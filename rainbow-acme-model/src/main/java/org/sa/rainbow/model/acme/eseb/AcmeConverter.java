package org.sa.rainbow.model.acme.eseb;

import incubator.pval.Ensure;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.text.MessageFormat;
import java.util.HashMap;
import java.util.Map;

import org.acmestudio.acme.core.exception.AcmeVisitorException;
import org.acmestudio.acme.core.resource.IAcmeResource;
import org.acmestudio.acme.core.resource.ParsingFailureException;
import org.acmestudio.acme.element.IAcmeSystem;
import org.acmestudio.acme.model.IAcmeModel;
import org.acmestudio.armani.ArmaniExportVisitor;
import org.acmestudio.standalone.resource.StandaloneResourceProvider;
import org.sa.rainbow.model.acme.AcmeModelInstance;

import edu.cmu.cs.able.typelib.jconv.TypelibJavaConversionRule;
import edu.cmu.cs.able.typelib.jconv.TypelibJavaConverter;
import edu.cmu.cs.able.typelib.jconv.ValueConversionException;
import edu.cmu.cs.able.typelib.prim.PrimitiveScope;
import edu.cmu.cs.able.typelib.prim.StringValue;
import edu.cmu.cs.able.typelib.scope.AmbiguousNameException;
import edu.cmu.cs.able.typelib.struct.Field;
import edu.cmu.cs.able.typelib.struct.StructureDataType;
import edu.cmu.cs.able.typelib.struct.StructureDataValue;
import edu.cmu.cs.able.typelib.struct.UnknownFieldException;
import edu.cmu.cs.able.typelib.type.DataType;
import edu.cmu.cs.able.typelib.type.DataValue;

public class AcmeConverter implements TypelibJavaConversionRule {

    private PrimitiveScope m_scope;

    public AcmeConverter (PrimitiveScope scope) {
        m_scope = scope;
    }

    @Override
    public boolean handles_java (Object value, DataType dst) {
        Ensure.not_null (value);
        if (value instanceof AcmeModelInstance) return dst == null || "rainbow_model".equals (dst.name ());
        return false;
    }

    @Override
    public boolean handles_typelib (DataValue value, Class<?> cls) {
        Ensure.not_null (value);
        if ("rainbow_model".equals (value.type ().name ()) && value instanceof StructureDataValue) {
            try {
                StructureDataValue sdv = (StructureDataValue )value;
                StructureDataType sdt = (StructureDataType )sdv.type ();
                DataValue type = sdv.value (sdt.field ("type"));
                return type instanceof StringValue && "Acme".equals (((StringValue )type).value ());
            }
            catch (UnknownFieldException | AmbiguousNameException e) {
                return false;
            }

        }
        return false;
    }

    @Override
    public DataValue from_java (Object value, DataType dst, TypelibJavaConverter converter)
            throws ValueConversionException {
        if ((dst == null || dst instanceof StructureDataType) && value instanceof AcmeModelInstance) {
            try {
                AcmeModelInstance instance = (AcmeModelInstance )value;
                StructureDataType sdt = (StructureDataType )dst;
                if (sdt == null) {
                    sdt = (StructureDataType )m_scope.find ("rainbow_model");
                }

                // Set up the housekeeping fields of the model
                Field cls = sdt.field ("cls");
                Field serialization = sdt.field ("serialization");
                Field type = sdt.field ("type");
                Field source = sdt.field ("source");
                Field name = sdt.field ("name");
                Field systemName = sdt.field ("system_name");
                Map<Field, DataValue> fields = new HashMap<> ();
                fields.put (cls, m_scope.string ().make (instance.getClass ().getCanonicalName ()));
                fields.put (type, m_scope.string ().make (instance.getModelType ()));
                fields.put (source, m_scope.string ().make (instance.getOriginalSource ()));
                fields.put (name, m_scope.string ().make (instance.getModelName ()));
                fields.put (systemName, m_scope.string ().make (instance.getModelInstance ().getQualifiedName ()));
                // Unparse the Acme for serialization
                // Need to unparse the entire model, not just the system, to pick up any
                // families and imports
                IAcmeModel model = instance.getModelInstance ().getContext ().getModel ();
                ByteArrayOutputStream baos = new ByteArrayOutputStream ();
                ArmaniExportVisitor visitor = new ArmaniExportVisitor (baos);
                model.visit (visitor, null);
                baos.flush ();
                baos.close ();
                fields.put (serialization, m_scope.string ().make (baos.toString ()));
                StructureDataValue sdv = sdt.make (fields);
                return sdv;
            }
            catch (AcmeVisitorException | UnknownFieldException | AmbiguousNameException | IOException e) {
                throw new ValueConversionException (e.getMessage ());
            }
        }
        throw new ValueConversionException (MessageFormat.format ("Could not convert from {0} to {1}", value
                .getClass ().toString (), (dst == null ? "rainbow_model" : dst.absolute_hname ())));
    }

    @Override
    public <T> T to_java (DataValue value, Class<T> cls, TypelibJavaConverter converter)
            throws ValueConversionException {
        if (value instanceof StructureDataValue) {
            try {
                StructureDataValue sdv = (StructureDataValue )value;
                StructureDataType sdt = (StructureDataType )value.type ();
                String serialization = converter.<String> to_java (sdv.value (sdt.field ("serialization")),
                        String.class);
                String modelClass = converter.<String> to_java (sdv.value (sdt.field ("cls")), String.class);
                String modelType = converter.<String> to_java (sdv.value (sdt.field ("type")), String.class);
                String modelName = converter.<String> to_java (sdv.value (sdt.field ("name")), String.class);
                String systemName = converter.<String> to_java (sdv.value (sdt.field ("system_name")), String.class);
                String source = converter.<String> to_java (sdv.value (sdt.field ("source")), String.class);

                // First, check that the class for the model is loaded, otherwise all is for naught
                Class<?> modelClazz = this.getClass ().forName (modelClass);
                IAcmeResource resource = StandaloneResourceProvider.instance ().acmeResourceForObject (
                        new ByteArrayInputStream (serialization.getBytes ()));
//                StandaloneResourceProvider.instance ().makeReadOnly (resource);

                Constructor<?> constructor = modelClazz.getConstructor (IAcmeSystem.class, String.class);
                Object r = constructor.newInstance (resource.getModel ().getSystem (systemName), source);
                T o = (T )r;
                return o;

            }
            catch (UnknownFieldException | IOException | AmbiguousNameException | ClassNotFoundException
                    | NoSuchMethodException | SecurityException | ParsingFailureException | InstantiationException
                    | IllegalAccessException | IllegalArgumentException | InvocationTargetException e) {
                throw new ValueConversionException (MessageFormat.format ("Could not convert from {0} to {1}",
                        value.toString (), (cls == null ? "rainbow_model" : cls.getCanonicalName ())), e);
            }
        }
        throw new ValueConversionException (MessageFormat.format ("Could not convert from {0} to {1}",
                value.toString (), (cls == null ? "rainbow_model" : cls.getCanonicalName ())));

    }

}
