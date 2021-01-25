/*
 * generated by Xtext 2.24.0
 */
package org.xtext.example.mydsl.generator

import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.example.mydsl.uml.AbstractClass
import org.xtext.example.mydsl.uml.Class
import org.xtext.example.mydsl.uml.ClassContent
import org.xtext.example.mydsl.uml.DefinedParameter
import org.xtext.example.mydsl.uml.Enum
import org.xtext.example.mydsl.uml.Function
import org.xtext.example.mydsl.uml.Heritage
import org.xtext.example.mydsl.uml.Implementation
import org.xtext.example.mydsl.uml.Interface
import org.xtext.example.mydsl.uml.InterfaceFunction
import org.xtext.example.mydsl.uml.Link
import org.xtext.example.mydsl.uml.StaticParameter
import org.xtext.example.mydsl.uml.UmlObject
import org.xtext.example.mydsl.uml.AbstractFunction
import java.util.List

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
 
class UmlGenerator extends AbstractGenerator {
	var links = newArrayList() 		// This list is used to keep a memory state of all links in order to process them after file generation
	var interfaces = newArrayList() // This list is super useful to implement super interface methods, otherwise we must use reflection
		
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {

		links.clear();
		interfaces.clear();

		links.addAll(resource.allContents.toIterable.filter(Link).toList)
		interfaces.addAll(resource.allContents.toIterable.filter(Interface).toList)
		
		System.out.println("Links :"+links)
		System.out.println("Interfaces :"+interfaces)
		
		for (umlObject: resource.allContents.toIterable.filter(UmlObject)){
			if(umlObject instanceof Class) fsa.generateFile((umlObject as Class).content.name + ".java", umlObject.compile());
			if(umlObject instanceof AbstractClass) fsa.generateFile((umlObject as AbstractClass).name+ ".java", umlObject.compile());
			if(umlObject instanceof Interface) fsa.generateFile((umlObject as Interface).name+".java", umlObject.compile);
			if(umlObject instanceof Enum) fsa.generateFile((umlObject as Enum).name+".java", umlObject.compile);
		}
		
		
	}
	
	def String processExtendLinks(UmlObject umlObject){
		var res = "extends "
		var isExtend = false
		val umlExtends = links.filter(Heritage).toList
		for (link: umlExtends){
			if( (umlObject instanceof Class && link.childrenClass == (umlObject as Class).content.name) ||
				(umlObject instanceof AbstractClass && link.childrenClass == (umlObject as AbstractClass).name) ||
				(umlObject instanceof Interface && link.childrenClass == (umlObject as Interface).name)
			){
				isExtend = true
				res += link.superClass
			}
		
		}
		return isExtend ? res : ""
	}
	
	def String processImplementLinks(UmlObject umlObject){
		var res = "implements "
		var isImplements = false
		var numberImplemented = 0;
		for (link: links.filter(Implementation).toList){
			if( (umlObject instanceof Class && link.childrenClass == (umlObject as Class).content.name) ||
				(umlObject instanceof AbstractClass && link.childrenClass == (umlObject as AbstractClass).name) ||
				(umlObject instanceof Interface && link.childrenClass == (umlObject as Interface).name)
			){
				isImplements = true
				numberImplemented++
				res += link.motherClass
				if(numberImplemented>0) res+=", "
			}
		}
		if (numberImplemented>1) res = res.substring(0, res.length-2)// Delete the last useless blank space and comma
		return isImplements ? res : "" 
	}
	
	def String processUmlObject(UmlObject umlObject){
		var res = "";
		res += processExtendLinks(umlObject)
		if(!res.isEmpty) res+=" "
		res += processImplementLinks(umlObject)
		return res;
	}
	/**
	 * For every *.java file created, if the Class, or AbstractClass implements an interface, 
	 * It returns the list of interfaces method that should be implemented
	 */
	def List<InterfaceFunction> getMethodsToImplement(UmlObject umlObject){
		if(!(umlObject instanceof Class || umlObject instanceof AbstractClass)) return emptyList()
		
		val res =links.filter(Implementation)
			.filter[link | link.childrenClass.equals(umlObject.class.toString)]
			// .map[implementation | interfaces.get(implementation.motherClass)]
			.map[interface | if (interface instanceof Interface) interface.functions else emptyList()]
			.head
		return res
	}
	
	def compileFunctionParameters(Function function){
		var res = ""
		for(param: function.params){
			if (param.modifier !== null){
				res += param.modifier+" "
			}
			res+=param.type + " "+param.name+", "
		}
		return res.substring(0, res.length - 2);
	}
	/**
	 * Generate the skeleton of a given class and compiles it's content
	 */
	private dispatch def compile(Class c) '''
		class «c.content.name» «processUmlObject(c)»{
			«c.content.compile»
			«val methodsToImplement = getMethodsToImplement(c)»
			«IF methodsToImplement !== null && !methodsToImplement.empty»
				«FOR method: methodsToImplement»
					«method.compile»{}
				«ENDFOR»
			«ENDIF»
			«System.out.println("Class : "+c)»
		}
	'''
	/**
	 * Generate the code for a given abstract class
	 */
	private dispatch def compile (AbstractClass aClass)'''
		abstract class «aClass.name» «processUmlObject(aClass)»{
			«aClass.params.compile»
			«aClass.functions.compile»
			«val methodsToImplement = getMethodsToImplement(aClass)»
			«IF methodsToImplement !== null && !methodsToImplement.empty»
				«FOR method: methodsToImplement»
					«method.compile»{}
				«ENDFOR»
			«ENDIF»
		}
	'''
	
	/**
	 * Generate the code for an interface
	 */
	private dispatch def compile (Interface umlInterface)'''
		interface «umlInterface.name»{
			«umlInterface.functions.compile»
		}
	'''
	/**
	 * Generate the code for an enum
	 */
	private dispatch def compile (Enum umlEnum)'''
		enum «umlEnum.name» {
			«FOR umlEnumConstant: umlEnum.params»
				«umlEnumConstant.name», 
			«ENDFOR»
		}
	'''
	/**
	 * A submethod of class, used to generate the body of a class
	 */
	private dispatch def compile(ClassContent cc) '''
		«IF cc.params !== null && !cc.params.empty»
			«cc.params.compile»
		«ENDIF»
		
		«IF cc.functions !== null && !cc.functions.empty»
			«cc.functions.compile»
		«ENDIF»
	'''
	
	/**
	 * All ELists<T> should be compiled here, because of Java erasure
	 * Basically, the Java compiler deletes the generic type contained in the list for overridden methods.
	 * As CharSequence.compile() is overridden several times, the generic type is erased, resulting in multiple methods with the same signature
	 * 
	 * Retrieving the generic type contained in a list is a very annoying task to perform, 
	 * we therefore used a workaround by assuming that each EList should only contain a single type
	 * we can then test the class type of the first element of that list 
	 */
	private dispatch def compile(EList<?> list) '''
	««« H
		«IF !list.empty»
			«IF !list.empty && list.get(0) instanceof DefinedParameter»
				«FOR param : list as EList<DefinedParameter>»
					«IF param.visibility.charValue == new Character('#')»protected«ELSEIF param.visibility.charValue == new Character('-')»private«ELSE»public«ENDIF» «IF param instanceof StaticParameter»static «ENDIF»«IF param.modifier !== null»«param.modifier» «ENDIF»«param.type» «param.name»;
				«ENDFOR»
			«ENDIF»
			«IF !list.empty && list.get(0) instanceof InterfaceFunction»
				«FOR function : list as EList<InterfaceFunction>»
						«IF function instanceof InterfaceFunction»
						«function.compile»
						«ENDIF»
				«ENDFOR»
			«ENDIF»
			«IF !list.empty && list.get(0) instanceof Function»
				«FOR function : list as EList<Function>»
				«function.compile»
				«ENDFOR»
			«ENDIF»
			«IF list.get(0) instanceof AbstractFunction»
				«FOR function : list as EList<AbstractFunction>»
					«function.compile»
				«ENDFOR»
			«ENDIF»
		«ENDIF»
	'''
	/**
	 * Generate the code for a given Function
	 */
	private dispatch def compile (Function function) '''
		«IF function.visibility.charValue == new Character('#')»protected«ELSEIF function.visibility.charValue == new Character('-')»private«ELSE»public«ENDIF» «function.returnType» «function.name»(«compileFunctionParameters(function)»){ 
			// TODO - Auto generated method
		}
	'''
	/**
	 * Generate the code for a given interface function
	 */
	private dispatch def compile (InterfaceFunction function) '''
		«IF function.visibility.charValue == new Character('#')»protected«ELSEIF function.visibility.charValue == new Character('-')»private«ELSE»public«ENDIF»«function.returnType» «function.name»();
	'''
	/**
	 * Generate the code for a given abstract function
	 */
	private dispatch def compile (AbstractFunction function)'''
		«IF function.visibility.charValue == new Character('#')»protected«ELSEIF function.visibility.charValue == new Character('-')»private«ELSE»public«ENDIF» abstract «function.returnType» «function.name»();
	''' 
}
