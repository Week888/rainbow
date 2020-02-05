/*
 * generated by Xtext 2.19.0
 */
package org.sa.rainbow.configuration.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import org.sa.rainbow.configuration.rcl.RainbowConfiguration

@ExtendWith(InjectionExtension)
@InjectWith(RclInjectorProvider)
class RclParsingTest {
	@Inject
	ParseHelper<RainbowConfiguration> parseHelper
	
	@Test
	def void loadModel() {
		val result = parseHelper.parse('''
			target test
		''')
		Assertions.assertNotNull(result)
		val errors = result.eResource.errors
		Assertions.assertTrue(errors.isEmpty, '''Unexpected errors: «errors.join(", ")»''')
	}
}