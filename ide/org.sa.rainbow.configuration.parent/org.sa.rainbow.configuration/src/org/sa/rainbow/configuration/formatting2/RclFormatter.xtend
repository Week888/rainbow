/*
 * generated by Xtext 2.21.0
 */
package org.sa.rainbow.configuration.formatting2

import com.google.common.base.Strings
import com.google.inject.Inject
import org.eclipse.xtext.formatting2.AbstractFormatter2
import org.eclipse.xtext.formatting2.IAutowrapFormatter
import org.eclipse.xtext.formatting2.IFormattableDocument
import org.sa.rainbow.configuration.rcl.Factory
import org.sa.rainbow.configuration.rcl.FactoryDefinition
import org.sa.rainbow.configuration.rcl.RainbowConfiguration
import org.sa.rainbow.configuration.rcl.RclPackage
import org.sa.rainbow.configuration.services.RclGrammarAccess
import org.eclipse.xtext.formatting2.regionaccess.IWhitespace
import org.eclipse.xtext.formatting2.regionaccess.IHiddenRegion

class RclFormatter extends AbstractFormatter2 {
	
	@Inject extension RclGrammarAccess

	def dispatch void format(RainbowConfiguration rainbowConfiguration, extension IFormattableDocument document) {
		// TODO: format HiddenRegions around keywords, attributes, cross references, etc. 
		for (_import : rainbowConfiguration.imports) {
			_import.format
		}
		for (declaredProperty : rainbowConfiguration.delcaredProperties) {
			declaredProperty.format
		}
		for (probe : rainbowConfiguration.probeTypes) {
			probe.format
		}
		for (probe : rainbowConfiguration.probes) {
			probe.format
		}
		for (gaugeType : rainbowConfiguration.gaugeTypes) {
			gaugeType.format
		}
		for (gauge : rainbowConfiguration.gauges) {
			gauge.format
		}
		for (effector : rainbowConfiguration.effectorTypes) {
			effector.format
		}
		for (effector : rainbowConfiguration.effectors) {
			effector.format
		}
		for (impactVector : rainbowConfiguration.impacts) {
			impactVector.format
		}
		rainbowConfiguration.export.format
		for (factory : rainbowConfiguration.factories) {
			factory.format
		}
	}

	def dispatch void format(Factory factory, extension IFormattableDocument document) {
		factory.regionFor.keyword("yields").prepend[oneSpace]
		factory.formatConditionally([doc |
			val extension slDoc = doc.requireFitsInLine
			factory.regionFor.feature(RclPackage.eINSTANCE.factory_Clazz).surround[oneSpace]
			factory.regionFor.keyword("{").append[newLine]
			factory.interior[indent]
			factory.defn.format
			
		],
		[
			extension doc |
			factory.regionFor.feature(RclPackage.eINSTANCE.factory_Clazz).prepend[oneSpace]
			factory.regionFor.keyword("{").append[newLine]
			factory.interior[indent]
			factory.defn.format
		]
		)
		
	}
	
	def dispatch void format(FactoryDefinition defn, extension IFormattableDocument document) {
		defn.regionFor.feature(RclPackage.Literals.FACTORY_DEFINITION__EXTENDS).append[newLine]
		defn.regionFor.feature(RclPackage.Literals.FACTORY_DEFINITION__MODEL_CLASS).append[newLine]
		defn.regionFor.feature(RclPackage.Literals.FACTORY_DEFINITION__LOAD_CMD).append[newLine].append[newLine]
		defn.regionFor.feature(RclPackage.Literals.FACTORY_DEFINITION__SAVE_CMD).append[newLine]
		val maxNameSize = defn.getMaxCommandNameLength
		
		for (command : defn.commands) {
			val IAutowrapFormatter af = [ region, wrapped, doc |
				val first = command.regionFor.keyword('is').previousHiddenRegion
				val last = command.regionFor.keyword(";").nextHiddenRegion
				doc.set(first, last, [newLine])
			]
			command.regionFor.keyword("command").append[oneSpace]
			command.regionFor.keyword("(").prepend[oneSpace].append[noSpace]
//			command.regionFor.feature(RclPackage.Literals.COMMAND_DEFINITION__NAME).append[space=Strings.repeat(" ", maxNameSize - command.name.length)]
//			command.regionFor.keyword(")").prepend[noSpace].append[oneSpace; autowrap; onAutowrap=af]
//			command.regionFor.feature(RclPackage.Literals.COMMAND_DEFINITION__CMD).append[autowrap; onAutowrap=af]
//			command.regionFor.keyword("is").prepend[space=Strings.repeat(" ", 8); newLine]
		}
	}
	
	def getMaxCommandNameLength(FactoryDefinition defn) {
		var max = 0
		for (command : defn.commands) {
			if (command.name.length > max) max = command.name.length
		}
		return max
	}
	
	
	// TODO: implement for FactoryDefinition, CommandDefinition, FormalParam, ImpactVector, ModelType, Export, DeclaredProperty, Probe, Effector, EffectorBody, GaugeType, Gauge, GaugeBody, GaugeTypeBody, JavaClassOrFactory, CommandReference, CommandCall, Actual, Component, Assignment, Value, Array, RichString
}