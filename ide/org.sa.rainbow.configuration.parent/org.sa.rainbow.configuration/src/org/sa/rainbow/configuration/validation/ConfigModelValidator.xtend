/*
 * generated by Xtext 2.19.0
 */
package org.sa.rainbow.configuration.validation

import com.google.inject.Inject
import com.google.inject.name.Named
import java.util.HashSet
import java.util.LinkedList
import java.util.List
import java.util.Map
import java.util.Set
import java.util.stream.Collectors
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.access.IJvmTypeProvider
import org.eclipse.xtext.common.types.util.Primitives
import org.eclipse.xtext.common.types.util.RawSuperTypes
import org.eclipse.xtext.util.Triple
import org.eclipse.xtext.util.Tuples
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.sa.rainbow.configuration.ConfigAttributeConstants
import org.sa.rainbow.configuration.Utils
import org.sa.rainbow.configuration.XtendUtils
import org.sa.rainbow.configuration.configModel.Array
import org.sa.rainbow.configuration.configModel.Assignment
import org.sa.rainbow.configuration.configModel.BooleanLiteral
import org.sa.rainbow.configuration.configModel.CommandCall
import org.sa.rainbow.configuration.configModel.CommandDefinition
import org.sa.rainbow.configuration.configModel.CommandReference
import org.sa.rainbow.configuration.configModel.Component
import org.sa.rainbow.configuration.configModel.ComponentType
import org.sa.rainbow.configuration.configModel.ConfigModelPackage
import org.sa.rainbow.configuration.configModel.DeclaredProperty
import org.sa.rainbow.configuration.configModel.DoubleLiteral
import org.sa.rainbow.configuration.configModel.Effector
import org.sa.rainbow.configuration.configModel.Factory
import org.sa.rainbow.configuration.configModel.FactoryDefinition
import org.sa.rainbow.configuration.configModel.FormalParam
import org.sa.rainbow.configuration.configModel.Gauge
import org.sa.rainbow.configuration.configModel.GaugeBody
import org.sa.rainbow.configuration.configModel.GaugeTypeBody
import org.sa.rainbow.configuration.configModel.IPLiteral
import org.sa.rainbow.configuration.configModel.ImpactVector
import org.sa.rainbow.configuration.configModel.IntegerLiteral
import org.sa.rainbow.configuration.configModel.ModelFactoryReference
import org.sa.rainbow.configuration.configModel.Probe
import org.sa.rainbow.configuration.configModel.PropertyReference
import org.sa.rainbow.configuration.configModel.Reference
import org.sa.rainbow.configuration.configModel.StringLiteral
import org.sa.rainbow.configuration.configModel.Value
import org.sa.rainbow.core.models.IModelInstance
import org.sa.rainbow.core.models.commands.AbstractLoadModelCmd
import org.sa.rainbow.core.models.commands.AbstractRainbowModelOperation
import org.sa.rainbow.core.models.commands.AbstractSaveModelCmd
import org.sa.rainbow.core.models.commands.ModelCommandFactory
import org.eclipse.xtext.conversion.impl.STRINGValueConverter
import java.util.regex.Pattern
import java.util.regex.PatternSyntaxException
import org.sa.rainbow.configuration.configModel.JavaClassOrFactory
import org.eclipse.xtext.common.types.JvmType

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class ConfigModelValidator extends AbstractConfigModelValidator {

	public static val ONLY_EXTEND_PROBE_TYPES_MSG = "A probe can only extend a probe type"
	public static val ONLY_EXTEND_PROBE_TYPES = "invalidProbeType"
	public static val MUST_SUBCLASS = "wrongtype"
	public static val MISSING_PROPERTY = "missingRequiredProperty"

	@Check
	def checkOnlyProbeAsSupertype(Probe probe) {
		var st = probe.superType
		if (st !== null) {
			if (!st.type) {
				error(
					ONLY_EXTEND_PROBE_TYPES_MSG,
					ConfigModelPackage.Literals.PROBE__SUPER_TYPE,
					ONLY_EXTEND_PROBE_TYPES
				)
			}
		}

	}

	@Check
	def checkProbeContainsRequiredAttributes(Probe probe) {
		if (!probe.type) {
			checkAttributes(
				probe?.properties?.assignment,
				probe.superType?.properties?.assignment,
				ConfigAttributeConstants.ALL_OFREQUIRED_PROBE_FIELDS,
				ConfigAttributeConstants.ONE_OFREQUIRED_PROBE_FIELDS,
				ConfigModelPackage.Literals.PROBE__PROPERTIES
			);
		}
		for (Assignment a : probe.properties?.assignment) {
			checkAssignmentType(a, ConfigAttributeConstants.PROBE_PROPERTY_TYPES, "")

		}
	}

	def void checkAssignmentType(Assignment a, Map<String, Map<String, Object>> types, String prefix) {
		if (a.value?.value instanceof Component) {
			for (ass : (a.value?.value as Component).assignment) {
				checkAssignmentType(ass, types, a.name + ":")
			}
		} else {
			checkTypeRule(types, a, prefix)
		}
	}

	@Check
	def checkOnlyEffectorAsSupertype(Effector effector) {
		var st = effector.superType
		if (st !== null) {
			if (!st.type) {
				error(
					"An effector can only extend an effector type",
					ConfigModelPackage.Literals.EFFECTOR__SUPER_TYPE,
					"invalidEffectorType"
				)
			}
		}
	}

	@Check
	def checkEffectorContainsRequiredAttributes(Effector effector) {
		if (!effector.type) {
			checkAttributes(
				effector?.body?.assignment,
				effector?.superType?.body?.assignment,
				ConfigAttributeConstants.ALL_OFREQUIRED_EFFECTOR_FIELDS,
				ConfigAttributeConstants.ONE_OFREQUIRED_EFFECTOR_FIELDS,
				ConfigModelPackage.Literals.EFFECTOR__BODY
			)
		}
		for (Assignment a : effector.body?.assignment) {
			checkAssignmentType(a, ConfigAttributeConstants.EFFECTOR_PROPERTY_TYPES, "")

		}
	}

	@Check
	def checkGaugeContainsRequiredAttributes(Gauge gauge) {
		checkAttributes(
			gauge?.body?.assignment,
			gauge?.superType?.body?.assignment,
			ConfigAttributeConstants.ALL_OFREQUIRED_GAUGE_FIELDS,
			ConfigAttributeConstants.OPTIONAL_GUAGE_FIELDS,
			ConfigModelPackage.Literals.GAUGE__BODY
		)
		checkSubAttributes(
			gauge?.body?.assignment,
			gauge?.superType?.body?.assignment,
			ConfigAttributeConstants.ALL_OFREQUIRED_GAUGE_SUBFILEDS,
			ConfigAttributeConstants.OPTIONAL_GAUGE_SUBFIELDS,
			ConfigModelPackage.Literals.GAUGE__BODY
		)
		for (Assignment a : gauge.body?.assignment) {
			checkAssignmentType(a, ConfigAttributeConstants.GAUGE_PROPERTY_TYPES, "")

		}
	}

//	@Check
//	def checkProbeValue(ProbeReference v) {
//		var p = v.eContainer
//		while (p != null && !(p.eContainer instanceof Probe))
//			p = p.eContainer
//		if (p != null) {
//			error(
//				"A probe cannot refer to another probe",
//				ConfigModelPackage.Literals.PROBE_REFERENCE__REFERABLE,
//				"noProbeReferencesInProbe"
//			)
//		}
//	}

	@Check
	def checkUtilityAssignment(Assignment ass) {
		val dp = EcoreUtil2.getContainerOfType(ass, DeclaredProperty)
		if (dp.component === ComponentType.UTILITY) {
			val sb = new StringBuffer()
			var eContainer = ass as EObject
			while (eContainer !== null) {
				eContainer = eContainer.eContainer
				if (eContainer instanceof Assignment) {
					sb.insert(0, ':')
					val par = (eContainer as Assignment)
					if (ConfigAttributeConstants.UTILITY_PROPERTY_TYPES.containsKey(par.name)) {
						sb.insert(0, par.name)
					}
				}
			}
			checkTypeRule(ConfigAttributeConstants.UTILITY_PROPERTY_TYPES, ass, sb.toString)
		}
	}

	@Check
	def checkAttributes(EList<Assignment> list, EList<Assignment> superlist, Set<String> requiredfields,
		Set<String> optionalFields, EReference reference) {
		for (String req : requiredfields) {
			var hasReq = list.exists [
				it.name == req
			];
			if (!hasReq && superlist !== null) {
				hasReq = superlist.exists [
					return it.name == req
				];
			}
			if (!hasReq) {
				warning(
					'''Expecting required field "«req»"''',
					reference,
					MISSING_PROPERTY,
					req
				)
			}
		}
		if (!optionalFields.isEmpty) {
			var hasOpt = false;
			for (String opt : optionalFields) {
				hasOpt = hasOpt || list.exists[return it.name == opt]
				if (superlist != null) {
					hasOpt = hasOpt || superlist.exists[return it.name == opt]
				}
			}
			if (!hasOpt) {
				var fields = optionalFields.map([return "\"" + it + "\""]).join(", ")
				warning(
					'''Expecting one of field «fields»''',
					reference,
					MISSING_PROPERTY,
					optionalFields.map[it].join(",")
				)
			}
		}

	}

	def checkSubAttributes(EList<Assignment> list, EList<Assignment> superlist, Map<String, Set<String>> allOfSubfields,
		Map<String, Set<String>> oneOfSubfields, EReference reference) {
		for (String key : allOfSubfields.keySet) {
			val compoundElement = list.findFirst [
				it.name == key && it?.value !== null && it.value.value instanceof Component
			]
			var hasCompoundReq = compoundElement !== null
			if (!hasCompoundReq && superlist !== null) {
				hasCompoundReq = superlist.exists [
					it.name == key && it?.value !== null && it.value.value instanceof Component
				]
			}
			if (!hasCompoundReq) {
				warning(
					'''Expecting required compound attribute "«key»"''',
					reference,
					MISSING_PROPERTY,
					key,
					Component.name
				)
			} else {
				val att = list != null ? list.stream.filter([it.name == key]).findAny : null
				val superAtt = superlist != null ? superlist.stream.filter([it.name == key]).findAny : null
				val allKeys = new HashSet<String>()
				if (att !== null && att.present) {
					allKeys.addAll((att.get.value.value as Component).assignment.map([it.name]))
				}
				if (superAtt !== null && superAtt.present) {
					allKeys.addAll((superAtt.get.value.value as Component).assignment.map[it.name])
				}
				if (!allKeys.containsAll(allOfSubfields.get(key))) {
					var fields = allOfSubfields.get(key).stream.filter([!allKeys.contains(it)]).collect(
						Collectors.toList)
					var fs = fields.map([return "\"" + it + "\""]).join(", ")
					if (compoundElement != null) {
						warning(
							'''"«key»" is missing the required fields «fs».''',
							compoundElement,
							ConfigModelPackage.Literals.ASSIGNMENT__VALUE,
							MISSING_PROPERTY,
							fields.map[it].join(",")
						)
					} else {
						warning(
							'''"«key»" is missing the required fields «fs».''',
							reference,
							MISSING_PROPERTY,
							fields.map[it].join(","),
							key
						)
					}
				}
			}
		}
	}

	@Inject
	@Named("jvmtypes") private IJvmTypeProvider.Factory jvmTypeProviderFactory;

	@Inject
	private RawSuperTypes superTypeCollector;

	@Check
	def checkGaugeTypeModelFactory(GaugeTypeBody gaugeType) {
		var model = gaugeType.mcf
		if (model != null) {
			
			if (model.referable instanceof JvmType) {
				var java = model.referable as JvmType
				var jvmTypeProvider = jvmTypeProviderFactory.createTypeProvider(gaugeType.eResource.resourceSet);
				
				
				
				var I2I = jvmTypeProvider.findTypeByName(MODEL_COMMAND_FACTORY_SUPERCLASS);
				var sts = superTypeCollector.collect(java);
				if (!sts.contains(I2I)) {
					error(
						'''«java.identifier» does not extend  «MODEL_COMMAND_FACTORY_SUPERCLASS»''',
						ConfigModelPackage.Literals.GAUGE_TYPE_BODY__MCF,
						ConfigModelValidator.MUST_SUBCLASS,
						MODEL_COMMAND_FACTORY_SUPERCLASS
					)
				}
			}

		}
	}

	@Check
	def checkCommandCall(CommandCall cc) {
		val gb = EcoreUtil2.getContainerOfType(cc, GaugeBody)
		if (gb !== null) {
			val g = EcoreUtil2.getContainerOfType(gb, Gauge)
			var  Object modelFactory = null
			if (gb.ref?.referable instanceof DeclaredProperty && (gb.ref?.referable as DeclaredProperty)?.component == ComponentType.MODEL &&
				(gb.ref?.referable as DeclaredProperty)?.^default.value instanceof Component) {
				modelFactory = ((gb.ref.referable as DeclaredProperty).^default.value as Component).assignment.findFirst[it.name == "factory"]
//				if (factory )
//				if (factory?.value?.value instanceof Reference && (factory.value.value as Reference).referable instanceof JvmDeclaredType) {
//					modelFactory = (factory.value.value as Reference).referable as JvmDeclaredType
//				}
			} else {
				if (g.superType !== null) {
					modelFactory = g.superType.body.mcf
//					if (g.superType.body.mcf.java.refera instanceof JvmDeclaredType)
//						modelFactory = g.superType.body.mcf as JvmDeclaredType
				}
			}
			if (modelFactory === null) {
				warning(
					'''Cannot check "«cc.command»" because no referenced model''',
					ConfigModelPackage.Literals.COMMAND_CALL__COMMAND,
					"cannotCheckCommand"
				)
			}
			if (g.superType !== null) {
				if (g.superType.body.commands.findFirst [
					it.name == cc.name
				] === null) {
					error(
						'''The command "«cc.name»" does not exists in «g.superType.name»''',
						ConfigModelPackage.Literals.COMMAND_CALL__NAME,
						"nocommand"
					)
				}
			}
			checkCommandCallElements(cc, modelFactory)
			return

		}
		val ef = EcoreUtil2.getContainerOfType(cc, Effector)
		if (ef !== null) {
			var JvmDeclaredType modelFactory = null
			if (gb.ref?.referable instanceof DeclaredProperty && (gb.ref?.referable as DeclaredProperty)?.component == ComponentType.MODEL &&
				(gb.ref?.referable as DeclaredProperty)?.^default.value instanceof Component) {
				val factory = ((gb.ref.referable as DeclaredProperty).^default.value as Component).assignment.findFirst[it.name == "factory"]
				if (factory?.value?.value instanceof Reference) {
					modelFactory = (factory.value.value as Reference).referable as JvmDeclaredType
				}
			}

			if (modelFactory === null) {
				warning(
					'''Cannot check "«cc.command»" because no referenced model''',
					ConfigModelPackage.Literals.COMMAND_CALL__COMMAND,
					"cannotCheckCommand"
				)
			}
			checkCommandCallElements(cc, modelFactory)
			return
		}
	}
	
	
	

	def checkCommandCallElements(CommandCall cc, Object modelFactory) {
		var Object cmf = null
		if (modelFactory instanceof Assignment) {
			cmf = (modelFactory as Assignment).value.value
		}
		else if (modelFactory instanceof JavaClassOrFactory) {
			val jcof = (modelFactory as JavaClassOrFactory) 
			if (jcof.java !== null) cmf = jcof.java
			else cmf = jcof.factory
		}
		val command = cc.command
		val Set<String> namedGroups = newHashSet
		if (cc.regexp !== null) {
			val regexp = XtendUtils.unpackString(cc.regexp, true)
			try {
				Pattern.compile(regexp)
				XtendUtils.fillNamedGroups(regexp, namedGroups)
			}
			catch (PatternSyntaxException e) {
				error ('''«e.message»''',
					ConfigModelPackage.Literals.COMMAND_CALL__REGEXP,
					"badregexp"
				)
			}
		}
		
		
		if (cmf instanceof Reference && (cmf as Reference).referable instanceof JvmDeclaredType) {
			val mf = (cmf as Reference).referable as JvmDeclaredType
			var commandMethod = mf.members.filter[it instanceof JvmOperation].filter [
				it.simpleName.equalsIgnoreCase(command) || it.simpleName.equalsIgnoreCase(command + "cmd")
			]
	
			if (commandMethod.empty) {
				error(
					'''"«command»" is not a valid command in «mf.identifier» ''',
					ConfigModelPackage.Literals.COMMAND_CALL__COMMAND,
					"nocommand"
				)
			} else {
				var method = commandMethod.get(0) as JvmOperation
				if (method.parameters.size != cc.actual.size + (cc.target != null ? 1 : 0)) {
					if (cc.actual == null && method.parameters.size > 0) {
					} else {
						error(
							'''"«command»" wrong number of parameters defined. Expecting «method.parameters.size-(cc.target!=null?1:0)» got «cc.actual.size»''',
							ConfigModelPackage.Literals.COMMAND_CALL__ACTUAL,
							"wrongparamnumbers"
						)
	
					}
				}
			}
		}
		else if (cmf instanceof ModelFactoryReference && (cmf as ModelFactoryReference).referable instanceof Factory) {
			val mf = (cmf as ModelFactoryReference).referable.defn
			var commandMethod = mf.commands.filter[it.name.equalsIgnoreCase(command)]
			
			if (commandMethod.empty) {
				error(
					'''"«command»" is not a valid command in «(cmf as ModelFactoryReference).referable.name» ''',
					ConfigModelPackage.Literals.COMMAND_CALL__COMMAND,
					"nocommand"
				)
			} else {
				val factoryCommand = commandMethod.get(0)
				if (factoryCommand.formal.size != cc.actual.size + (cc.target != null ? 1 : 0)) {
					if (cc.actual == null && factoryCommand.formal.size > 0) {
						
					} else {
						error(
							'''"«command»" wrong number of parameters defined. Expecting «factoryCommand.formal.size-(cc.target!=null?1:0)» got «cc.actual.size»''',
							ConfigModelPackage.Literals.COMMAND_CALL__ACTUAL,
							"wrongparamnumbers"
						)
	
					}
				}
				else {
					for (actual : cc.actual) {
						if (actual.ref && cc.regexp !== null) {
							var name = actual.ng
							var lit = ConfigModelPackage.Literals.ACTUAL__NG
							if (name === null) {
								name = Integer.toString(actual.ag)
								lit = ConfigModelPackage.Literals.ACTUAL__AG
							} 
							if (!namedGroups.contains(name)) {
								warning('''«name» should be a valid group from «XtendUtils.unpackString(cc.regexp, true)»''',
									actual,
									lit,
									"badregexpreference"
								)
							}
						}
					}
				}
//				else {
//					var i = 0
//					for (param : factoryCommand.formal) {
//						if (param.name != "target") {
//							val paramTypeName = getTypeName(param)
//							if (paramTypeName != cc.actual.get(i).) {
//								error(
//										'''Parameter «i» expecting «paramTypeName», received «cr.formal.get(i).simpleName».''',
//										ConfigModelPackage.Literals.COMMAND_REFERENCE__FORMAL,
//										"wrongType"
//									)
//							}
//							i = i + 1
//						}
//						else {
//							val paramTypeName = getTypeName(param)
//							if (paramTypeName != cr.target) {
//								error(
//										'''Target type expecting «paramTypeName», received «cr.target».''',
//										ConfigModelPackage.Literals.COMMAND_REFERENCE__TARGET,
//										"wrongType"
//									)
//							}
//						}
//					}
//				}
			}
		}
	}

	@Check
	def checkCommandSignature(CommandReference cr) {
		if (cr.eContainer.eClass == ConfigModelPackage.Literals.GAUGE_TYPE_BODY) {
			var gaugeType = cr.eContainer as GaugeTypeBody
			if (gaugeType === null) {
				if (gaugeType.mcf === null) {
					if (gaugeType.mcf !== null && !(gaugeType.mcf.referable instanceof JvmDeclaredType || gaugeType.mcf.referable instanceof Factory)) {
						warning(
							'''"«cr.command» cannot be checked because there is no model defined"''',
							ConfigModelPackage.Literals.COMMAND_REFERENCE__COMMAND,
							"cannotCheckCommand"
						)
						return 
					}
				}
			}
			val command = cr.command
			
			val java = gaugeType.mcf.referable instanceof JvmDeclaredType?gaugeType.mcf.referable as JvmDeclaredType:null
			val factory = gaugeType.mcf.referable instanceof Factory?gaugeType.mcf.referable as Factory:null
			
			
			if (java !== null) {
				var type = java
				
				var commandMethod = type.members.filter[it instanceof JvmOperation].filter [
					it.simpleName.equalsIgnoreCase(command) || it.simpleName.equalsIgnoreCase(command + "cmd")
				]
	
				if (commandMethod.empty) {
					error(
						'''"«command»" is not a valid command in «type.identifier» ''',
						ConfigModelPackage.Literals.COMMAND_REFERENCE__COMMAND,
						"nocommand"
					)
				} else {
					var method = commandMethod.get(0) as JvmOperation
					if (method.parameters.size != cr.formal.size + (cr.target != null ? 1 : 0)) {
						if (cr.formal == null && method.parameters.size > 0) {
						} else {
							error(
								'''"«cr.command»" wrong number of parameters defined. Expecting «method.parameters.size-(cr.target!=null?1:0)» got «cr.formal.size»''',
								ConfigModelPackage.Literals.COMMAND_REFERENCE__FORMAL,
								"wrongparamnumbers"
							)
							return
						}
					}
					var first = true
					val prim = new Primitives()
					var i = 0
					for (param : method.parameters) {
						if (first && cr.target != null) {
							if (prim.isPrimitive(param.parameterType)) {
								warning(
									'''«type.simpleName».«method.simpleName» may need a target''',
									ConfigModelPackage.Literals.COMMAND_REFERENCE__COMMAND,
									"mayNeedTarget"
								)
							}
						} else {
							if (param.parameterType.simpleName != cr.formal.get(i).simpleName) {
								error(
									'''Parameter «i» expecing «param.parameterType.simpleName», received «cr.formal.get(i).simpleName».''',
									ConfigModelPackage.Literals.COMMAND_REFERENCE__FORMAL,
									"wrongType"
								)
							}
							i = i + 1
						}
						first = false
					}
				}
			
			}
			else if (factory != null) {
				
				val factoryCommands = factory.defn.commands.filter[it.name.equalsIgnoreCase(command)]
				if (factoryCommands.empty) {
					error(
						'''"«command»" is not a valid command in «factory.name» ''',
						ConfigModelPackage.Literals.COMMAND_REFERENCE__COMMAND,
						"nocommand"
					)
				}
				else {
					val factoryCommand = factoryCommands.get(0)
					if (factoryCommand.formal.size != cr.formal.size + (cr.target != null ? 1 : 0)) {
						if (cr.formal == null && factoryCommand.formal.size > 0) {
							return
						} else {
							error(
								'''"«cr.command»" wrong number of parameters defined. Expecting «factoryCommand.formal.size-(cr.target!=null?1:0)» got «cr.formal.size»''',
								ConfigModelPackage.Literals.COMMAND_REFERENCE__FORMAL,
								"wrongparamnumbers"
							)
							return
						}
					} 
					// Check the targets
					if (factoryCommand.formal.findFirst[it.name=="target"] !== null && cr.target === null) {
						error(
								'''"«cr.command»" does not specify a needed target''',
								ConfigModelPackage.Literals.COMMAND_REFERENCE__FORMAL,
								"wrongparamnumbers"
							)
							return
					}
					if (cr.target !== null && factoryCommand.formal.findFirst[it.name=="target"] === null) {
						error ('''«cr.command» specifies a target not in the factory: «cr.target»''',
							ConfigModelPackage.Literals.COMMAND_REFERENCE__TARGET,
							"unknowntarget"
						)
					}
					var i = 0
					for (param : factoryCommand.formal) {
						if (param.name != "target") {
							val paramTypeName = getTypeName(param)
							if (paramTypeName != cr.formal.get(i).simpleName) {
								error(
										'''Parameter «i» expecting «paramTypeName», received «cr.formal.get(i).simpleName».''',
										ConfigModelPackage.Literals.COMMAND_REFERENCE__FORMAL,
										"wrongType"
									)
							}
							i = i + 1
						}
						else {
							val paramTypeName = getTypeName(param)
							if (paramTypeName != cr.target) {
								error(
										'''Target type expecting «paramTypeName», received «cr.target».''',
										ConfigModelPackage.Literals.COMMAND_REFERENCE__TARGET,
										"wrongType"
									)
							}
						}
					}
				}
			}
//			var tries=[cr.command, cr.command.toLowerCase, cr.commmand]
//			while (method == null)
		}
	}
	
	def getTypeName(FormalParam param) {
		if (param.type.acme !== null) {
			val ar = param.type.acme.referable
			return XtendUtils.getAcmeTypeName(ar)
		}
		if (param.type.java != null) {
			return param.type.java.referable.simpleName
		}
		if (param.type.base !== null) {
			return param.type.base.getName()
		}
			
	}

	@Check
	def checkClassAssignments(DeclaredProperty assignment) {
		if (assignment?.^default.value instanceof Reference) {
			val subType = (assignment.^default.value as Reference).referable
			if (assignment.name.matches(".*class_[0-9]+$")) {
				val checkName = assignment.name.substring(0, assignment.name.lastIndexOf('_')) + "*"
				val superClass = ConfigAttributeConstants.PROPERTY_VALUE_CLASSES.get(checkName)
				if (superClass !== null) {
					val jvmTypeProvider = jvmTypeProviderFactory.createTypeProvider(assignment.eResource.resourceSet)
					val superType = jvmTypeProvider.findTypeByName(superClass)
					var sts = superTypeCollector.collect(subType)
					if (!sts.contains(superType)) {
						error(
							'''«subType.simpleName» is not a subclass of «superClass»''',
							ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT,
							ConfigModelValidator.MUST_SUBCLASS,
							superClass
						)
					}
				}
			}
		}
	}

	@Check
	def checkComponentPropertiesAreComponent(DeclaredProperty dp) {
		if (dp.component != ComponentType.PROPERTY) {
			if (!(dp.^default.value instanceof Component)) {
				error(
					'''Values for «dp.component» must be compound values''',
					ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT,
					"incorrectValue"
				)
			}
		}
	}

	@Check
	def checkComponentPropertyFields(DeclaredProperty dp) {
		if (dp.component != ComponentType.PROPERTY) {
			switch dp.component {
				case ANALYSIS: {
					checkAttributes((dp.^default.value as Component).assignment, null,
						ConfigAttributeConstants.ALL_OFREQUIRED_ANALYSIS_FIELDS, #{},
						ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT)

				}
				case EFFECTORMANAGER: {
					checkAttributes((dp.^default.value as Component).assignment, null,
						ConfigAttributeConstants.ALL_OFREQUIRED_EFFECTOR_MANAGER_FIELDS, #{},
						ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT)

				}
				case EXECUTOR: {
					checkAttributes((dp.^default.value as Component).assignment, null,
						ConfigAttributeConstants.ALL_OFREQUIRED_EXECUTOR_FIELDS, #{},
						ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT)
				}
				case GUI: {
				}
				case MANAGER: {
					checkAttributes((dp.^default.value as Component).assignment, null,
						ConfigAttributeConstants.ALL_OFREQUIRED_MANANGER_FIELDS, #{},
						ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT)

				}
				case MODEL: {
					checkAttributes((dp.^default.value as Component).assignment, null,
						ConfigAttributeConstants.ALL_OFREQUIRED_MODEL_FIELDS, #{},
						ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT)
				}
				case PROPERTY: {
				}
				case UTILITY: {
					checkAttributes((dp.^default.value as Component).assignment, null,
						ConfigAttributeConstants.ALL_OFREQUIRED_UTILITY_FIELDS, #{},
						ConfigModelPackage.Literals.DECLARED_PROPERTY__DEFAULT)
				}
			}
		}
	}

	@Check
	def checkComponentPropertyFieldTypes(Assignment dp) {
		val parent = EcoreUtil2.getContainerOfType(dp, DeclaredProperty)
		if (parent?.component !== null && parent?.component == ComponentType.GUI) {
			var rent = EcoreUtil2.getContainerOfType(dp.eContainer, org.sa.rainbow.configuration.configModel.Assignment);
			var name = ""
			while (rent !== null) {
				name = rent.name + ":" + name
				rent = EcoreUtil2.getContainerOfType(rent.eContainer, org.sa.rainbow.configuration.configModel.Assignment);
			}
			checkTypeRule(ConfigAttributeConstants.GUI_PROPERTY_TUPES, dp, name)
		}
		else if (parent?.component !== null && parent?.component != ComponentType.PROPERTY) {
			val rule = ConfigAttributeConstants.COMPONENT_PROPERTY_TYPES.get(parent.component)
			checkTypeRule(rule, dp)
		}
	}

	def void checkTypeRule(Map<String, Map<String, Object>> rule, Assignment dp) {
		checkTypeRule(rule, dp, "")
	}

	protected def void checkTypeRule(Map<String, Map<String, Object>> rule, Assignment dp, String prefix) {
		if (rule !== null) {
			val lookupName = prefix == "" ? dp.name : (prefix + dp.name)
			val fieldRule = rule.get(lookupName) as Map<String, Object>
			if (fieldRule !== null) {
				val (Value)=>boolean func = fieldRule.get('func') as (Value)=>boolean
				if (func !== null) {
					if (!func.apply(dp.value)) {
						error(
							'''«dp.name» «fieldRule.get('msg')»''',
							dp,
							ConfigModelPackage.Literals.ASSIGNMENT__VALUE,
							"invalidType"
						)
					}
				} else {
					var extends = fieldRule.get('extends') as List<Class>
					var ok = false
					for (class : extends) {
						ok = ok || checkClass(dp, class)
					}
					if (!ok) {
						error(
							'''«dp.name» «fieldRule.get('msg')»''',
							dp,
							ConfigModelPackage.Literals.ASSIGNMENT__VALUE,
							MUST_SUBCLASS,
							extends.map[it.name].join(",")
						)
					}
					if (extends.contains(Array) && dp.value.value instanceof Array) {
						val furtherCheck = fieldRule.get(
							'checkEach') as Function1<Array, LinkedList<Triple<String, EObject, EStructuralFeature>>>
						for (e : furtherCheck.apply(dp.value.value as Array)) {
							error(e.first, e.second, e.third)
						}
					}
				}
				
			}

		}
	}

	protected def boolean checkClass(Assignment dp, Class clazz) {
		if(clazz == StringLiteral) return dp.value.value instanceof StringLiteral
		if(clazz == BooleanLiteral) return dp.value.value instanceof BooleanLiteral
		if(clazz == IntegerLiteral) return dp.value.value instanceof IntegerLiteral
		if(clazz == DoubleLiteral) return dp.value.value instanceof DoubleLiteral
		if(clazz == Component) return dp.value.value instanceof Component
		if(clazz == IPLiteral) return dp.value.value instanceof IPLiteral
		if(clazz == PropertyReference) return dp.value.value instanceof PropertyReference
//		if(clazz == ProbeReference) return dp.value.value instanceof ProbeReference
		if(clazz == Array) return dp.value.value instanceof Array
		ConfigAttributeConstants.subclasses(dp.value, clazz.name)
	}

	public static val CHECK_UTILITY_MONOTONIC = [ Array a |
		{
			val errors = new LinkedList<Triple<String, EObject, EStructuralFeature>>()
			var first = true
			var double lastVal = 0.0
			var goingUp = false
			var goingDown = false
			for (v : a.values) {
				if (!(v.value instanceof Array)) {
					errors.add(
						Tuples.create('''Array value needs to be an array of two numbers''', v,
							ConfigModelPackage.Literals.VALUE__VALUE))
				} else {
					val pair = v.value as Array
					if (pair.values.size != 2) {
						errors.add(
							Tuples.create('''Array value needs to be an array of two numbers''', v,
								ConfigModelPackage.Literals.VALUE__VALUE))
					} else {
						val thisVal = getNumber(pair.values.get(1))
						if (!first) {
							if (lastVal < thisVal) {
								goingUp = true
							} else if (lastVal > thisVal) {
								goingDown = true
							}
						} else {
							first = false
						}
						lastVal = thisVal
					}

				}
			}
			if (goingUp && goingDown) {
				errors.add(
					Tuples.create('''Utilities need to be monotonic''', a, ConfigModelPackage.Literals.ARRAY__VALUES))
			}
			errors

		}
	]

	public static val CHECK_EACH_SCENARIO = [ Array a |
		{
			val errors = new LinkedList<Triple<String, EObject, EStructuralFeature>>()
			val dp = Utils.getContainerOfType(a, Component, [ EObject v |
				v instanceof Component && (v as Component).assignment.exists[it.name == "utilities"]
			])
			var definedUtilities = (dp.assignment.findFirst[it.name == "utilities"]?.value.value as Component).
				assignment.map[it.name]
			for (v : a.values) {
				if (!(v.value instanceof Component)) {
					errors.add(
						Tuples.create('''Scenario should only contain composites''', a,
							ConfigModelPackage.Literals.ARRAY__VALUES))
				} else {
					var sum = 0.0
					val scenario = v.value as Component
					for (ass : scenario.assignment) {
						if (ass.name != 'name') {
							sum += getNumber(ass.value)
							if (!definedUtilities.contains(ass.name)) {
								errors.add(
									Tuples.create('''«ass.name» must refer to a utility defined in utilities''', ass,
										ConfigModelPackage.Literals.ASSIGNMENT__NAME))
							}
						}
					}
					if (sum != 1.0) {
						errors.add(
							Tuples.create('''The utilities in a scenario must sum to 1''', scenario,
								ConfigModelPackage.Literals.COMPONENT__ASSIGNMENT))
					}
				}
			}
			errors
		}
	]

	def static getNumber(Value value) {
		val v = value.value
		switch v {
			IntegerLiteral: Double.valueOf(v.value)
			DoubleLiteral: Double.valueOf(v.value)
			default: 0.0
		}
	}

	@Check
	def checkImpact(ImpactVector iv) {
		if (!(iv.utilityModel.referable instanceof DeclaredProperty) || (iv.utilityModel.referable as DeclaredProperty)?.component !== ComponentType.UTILITY) {
			error(
				'''Impact vector referring to non-utility model «iv.utilityModel.referable?.name»''',
				iv.utilityModel,
				ConfigModelPackage.Literals.IMPACT_VECTOR__UTILITY_MODEL
			)
			return
		}
		var definedUtilities = (((iv.utilityModel.referable as DeclaredProperty).^default.value as Component).assignment.findFirst [
			it.name == "utilities"
		]?.value.value as Component).assignment.map[it.name]
		for (ass : iv.component.assignment) {
			if (!definedUtilities.contains(ass.name)) {
				error('''Undefined utility «ass.name»''', ass, ConfigModelPackage.Literals.ASSIGNMENT__NAME)
			}
		}
	}

	static val LOAD_MODEL_CMD_SUPERCLASS = typeof(AbstractLoadModelCmd).name
	static val SAVE_MODEL_CMD_SUPERCLASS = typeof(AbstractSaveModelCmd).name
	static val MODEL_COMMAND_FACTORY_SUPERCLASS = typeof(ModelCommandFactory).name
	static val RAINBOW_OPERATION_SUPERCLASS = typeof(AbstractRainbowModelOperation).name
	static val MODEL_SUPERCLASS = typeof(IModelInstance).name

	@Check
	def checkFactoryDefinition(FactoryDefinition factory) {
		if (!ConfigAttributeConstants.subclasses(factory.loadCmd, ConfigModelValidator.LOAD_MODEL_CMD_SUPERCLASS,
			factory.eResource)) {
			error(
				'''«factory.loadCmd.qualifiedName» must subclass «ConfigModelValidator.LOAD_MODEL_CMD_SUPERCLASS»''',
				factory,
				ConfigModelPackage.Literals.FACTORY_DEFINITION__LOAD_CMD,
				MUST_SUBCLASS,
				ConfigModelValidator.LOAD_MODEL_CMD_SUPERCLASS
			)
		}
		if (factory.saveCmd !== null &&
			!ConfigAttributeConstants.subclasses(factory.saveCmd, SAVE_MODEL_CMD_SUPERCLASS, factory.eResource)) {
			error(
				'''«factory.saveCmd.qualifiedName» must subclass «SAVE_MODEL_CMD_SUPERCLASS»''',
				factory,
				ConfigModelPackage.Literals.FACTORY_DEFINITION__SAVE_CMD,
				MUST_SUBCLASS,
				SAVE_MODEL_CMD_SUPERCLASS
			)
		}
		if (factory.extends !== null &&
			!ConfigAttributeConstants.subclasses(factory.extends, MODEL_COMMAND_FACTORY_SUPERCLASS,
				factory.eResource)) {
			error(
				'''«factory.saveCmd.qualifiedName» must subclass «MODEL_COMMAND_FACTORY_SUPERCLASS»''',
				factory,
				ConfigModelPackage.Literals.FACTORY_DEFINITION__EXTENDS,
				MUST_SUBCLASS,
				MODEL_COMMAND_FACTORY_SUPERCLASS
			)
		}
		if (!ConfigAttributeConstants.subclasses(factory.modelClass, MODEL_SUPERCLASS, factory.eResource)) {
			error(
				'''«factory.modelClass.qualifiedName» must subclass «MODEL_SUPERCLASS»''',
				factory,
				ConfigModelPackage.Literals.FACTORY_DEFINITION__MODEL_CLASS,
				MUST_SUBCLASS,
				MODEL_SUPERCLASS
			)
		}
	}

	@Check
	def checkCommandDefinition(CommandDefinition cmd) {
		if (!ConfigAttributeConstants.subclasses(cmd.cmd, RAINBOW_OPERATION_SUPERCLASS, cmd.eResource)) {
			error(
				'''«cmd.cmd.qualifiedName» must extend «RAINBOW_OPERATION_SUPERCLASS»''',
				cmd,
				ConfigModelPackage.Literals.COMMAND_DEFINITION__CMD,
				MUST_SUBCLASS,
				RAINBOW_OPERATION_SUPERCLASS
			)
		}

		val factory = EcoreUtil2.getContainerOfType(cmd, FactoryDefinition)
		if (!(cmd.cmd instanceof JvmDeclaredType)) {
			return
		}
		val cmdClass = cmd.cmd as JvmDeclaredType
		var compatibleConstructors = cmdClass.declaredConstructors.filter([
			if (it.parameters.size == cmd.formal.size + 2) {
				val firstString = it.parameters.get(0).parameterType.qualifiedName == "java.lang.String"
				val secondModel = it.parameters.get(1).parameterType.qualifiedName == factory.modelClass.qualifiedName
				return firstString && secondModel
			}
			false
		])
		if (compatibleConstructors.nullOrEmpty) {
			var myParams = cmd.formal.map [
				XtendUtils.formalTypeName(it, true)
			].join(", ")
			error(
				'''«cmdClass.simpleName» must have constructor with parameters String, «factory.modelClass.simpleName», «myParams»''',
				cmd,
				ConfigModelPackage.Literals.COMMAND_DEFINITION__CMD,
				"ConstructurIncompatible"
			)
		} else {
			val cstr = compatibleConstructors.get(0)
			for (var i = 0; i < cmd.formal.size; i++) {
				if (cstr.parameters.get(i + 2).parameterType.simpleName != "String") {
					val cstrType = cstr.parameters.get(i + 2).parameterType
					val formalType = cmd.formal.get(i)
					if(cstrType.qualifiedName != XtendUtils.formalTypeName(formalType,false)) {
						error('''Found «XtendUtils.formalTypeName(formalType,false)», expecting «cstr.simpleName»''',
							formalType, ConfigModelPackage.Literals.FORMAL_PARAM__TYPE,
							"incorrectType"
						)
					}
				}
			}
		}
		if (cmd.formal.drop(1).exists[it.name == "target"]) {
			warning(
				'''Only the first argument of a command can be 'target''',
				cmd,
				ConfigModelPackage.Literals.COMMAND_DEFINITION__FORMAL,
				"badTarget"
			)
		} else
		if (cmd.formal.get(0).name != "target") {
			warning(
				'''The first argument of a command should be 'target''',
				cmd,
				ConfigModelPackage.Literals.COMMAND_DEFINITION__FORMAL,
				"badTarget"
			)
		}

	}



}
