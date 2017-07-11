import 'dart:async';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:jaguar_http/jaguar_http.dart';
import 'package:jaguar_http/jaguar_http_generator.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/annotation.dart';
import 'package:source_gen/src/utils.dart';
import 'package:code_builder/code_builder.dart';

class JaguarHttpGenerator extends GeneratorForAnnotation<JaguarHttp> {
  const JaguarHttpGenerator();

  Future<String> generateForAnnotatedElement(Element element,
      JaguarHttp annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      var friendlyName = friendlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JaguarHttp annotation from `$friendlyName`.');
    }

    return _buildImplementionClass(annotation, element);
  }

  String _buildImplementionClass(JaguarHttp annotation, ClassElement element) {
    var friendlyName = element.name;

    ReferenceBuilder base = reference(friendlyName);
    ClassBuilder clazz = new ClassBuilder(
        annotation.name ?? "${friendlyName}Impl",
        asExtends: base);

    _buildConstructor(clazz);

    element.methods.forEach((MethodElement m) {
      ElementAnnotation methodAnnot = _getMethodAnnotation(m);
      if (methodAnnot != null &&
          m.isAbstract &&
          m.returnType.isDartAsyncFuture) {
        TypeBuilder returnType = _genericTypeBuilder(m.returnType);

        MethodBuilder methodBuilder = new MethodBuilder(m.name,
            returnType: returnType, modifier: MethodModifier.asAsync);

        final statements = [
          _generateUrl(m, methodAnnot),
          _generateRequest(m, methodAnnot),
        ];

        if (_needInterceptor(element)) {
          statements.add(_generateInterceptRequest());
        }

        statements.addAll([
          _generateSendRequest(),
          varField("response"),
          _generateResponseProcess(m),
        ]);

        if (_needInterceptor(element)) {
          statements.add(_generateInterceptResponse());
        }

        statements.add(reference("response").asReturn());

        methodBuilder.addStatements(statements);

        m.parameters.forEach((ParameterElement param) {
          if (param.parameterKind == ParameterKind.NAMED) {
            methodBuilder.addNamed(new ParameterBuilder(param.name,
                type: new TypeBuilder(param.type.name)));
          } else {
            methodBuilder.addPositional(new ParameterBuilder(param.name,
                type: new TypeBuilder(param.type.name)));
          }
        });

        clazz.addMethod(methodBuilder);
      }
    });

    return clazz.buildClass().toString();
  }

  bool _needInterceptor(ClassElement element) =>
      element.allSupertypes.any((InterfaceType t) => t.name ==
          "JaguarInterceptors");


  _buildConstructor(ClassBuilder clazz) {
    clazz.addField(varFinal("baseUrl", type: new TypeBuilder("String")));
    clazz.addField(varFinal("headers", type: new TypeBuilder("Map")));
    clazz.addField(varFinal("_client", type: new TypeBuilder("Client")));
    clazz.addField(
        varFinal("serializers", type: new TypeBuilder("SerializerRepo")));

    clazz.addConstructor(new ConstructorBuilder()
      ..addPositional(
          new ParameterBuilder("_client"), asField: true)..addPositional(
          new ParameterBuilder("baseUrl"), asField: true)
      ..addNamed(new ParameterBuilder(
          "headers", type: new TypeBuilder("Map")))..addNamed(
          new ParameterBuilder("serializers",
              type: new TypeBuilder("SerializerRepo")))
      ..addInitializer("headers",
          toExpression: new ExpressionBuilder.raw(
                  (
                  _) => "headers ?? { 'content-type': 'application/json' }"))..addInitializer(
          "serializers",
          toExpression: new ExpressionBuilder.raw(
                  (_) => "serializers ?? new JsonRepo()")));
  }

  ElementAnnotation _getMethodAnnotation(MethodElement method) =>
      method.metadata.firstWhere((ElementAnnotation annot) {
        return _methodsAnnotations.any((type) => matchAnnotation(type, annot));
      }, orElse: () => null);

  ElementAnnotation _getParamAnnotation(ParameterElement param) =>
      param.metadata.firstWhere((ElementAnnotation annot) {
        return matchAnnotation(Param, annot);
      }, orElse: () => null);

  ElementAnnotation _getBodyAnnotation(ParameterElement param) =>
      param.metadata.firstWhere((ElementAnnotation annot) {
        return matchAnnotation(Body, annot);
      }, orElse: () => null);

  final _methodsAnnotations = const [Get, Post, Delete, Put, Patch];

  DartType _genericOf(DartType type) {
    return type is InterfaceType && type.typeArguments.isNotEmpty
        ? type.typeArguments.first
        : null;
  }

  TypeBuilder _genericTypeBuilder(DartType type) {
    final generic = _genericOf(type);
    if (generic == null) {
      return new TypeBuilder(type.name);
    }
    return new TypeBuilder(type.name, genericTypes: [
      _genericTypeBuilder(generic),
    ]);
  }

  DartType _getResponseType(DartType type) {
    final generic = _genericOf(type);
    if (generic == null) {
      return type;
    }
    if (generic.isDynamic) {
      return null;
    }
    return _getResponseType(generic);
  }

  StatementBuilder _generateUrl(MethodElement method,
      ElementAnnotation methodAnnot) {
    final annot = instantiateAnnotation(methodAnnot) as Req;

    String value = "${annot.url}";
    method.parameters?.forEach((ParameterElement p) {
      var pAnnot = _getParamAnnotation(p);
      pAnnot = pAnnot != null ? instantiateAnnotation(pAnnot) : null;
      if (pAnnot != null) {
        String key = ":${(pAnnot as Param).name ?? p.name}";
        value = value.replaceFirst(key, "\${${p.name}}");
      }
    });

    return literal('\$baseUrl$value').asFinal("url");
  }

  StatementBuilder _generateRequest(MethodElement method,
      ElementAnnotation methodAnnot) {
    final annot = instantiateAnnotation(methodAnnot) as Req;

    final params = {
      "method": new ExpressionBuilder.raw((_) => "'${annot.method}'"),
      "url": reference("url"),
      "headers": reference("headers")
    };

    method.parameters?.forEach((ParameterElement p) {
      var pAnnot = _getBodyAnnotation(p);
      pAnnot = pAnnot != null ? instantiateAnnotation(pAnnot) : null;
      if (pAnnot != null) {
        params["body"] =
            reference("serializers").invoke("serialize", [reference(p.name)]);
      }
    });

    return reference("JaguarRequest")
        .newInstance([], named: params).asVar("request");
  }

  StatementBuilder _generateInterceptRequest() =>
      reference("interceptRequest")
          .call([reference("request")]).asAssign(reference("request"));

  StatementBuilder _generateInterceptResponse() =>
      reference("interceptResponse")
          .call([reference("response")]).asAssign(reference("response"));

  StatementBuilder _generateSendRequest() =>
      varFinal("rawResponse",
          value: reference("request").invoke(
              "send", [new ExpressionBuilder.raw((_) => "_client")]).asAwait());

  StatementBuilder _generateResponseProcess(MethodElement method) {
    final named = {};

    final responseType = _getResponseType(method.returnType);

    if (responseType != null) {
      named["type"] = new ExpressionBuilder.raw((_) => "${responseType.name}");
    }

    return ifThen(
        reference("responseSuccessful").call([reference("rawResponse")]))
      ..addStatement(reference("JaguarResponse").newInstance([
        reference("serializers").invoke(
            "deserialize", [reference("rawResponse.body")],
            namedArguments: named),
        reference("rawResponse")
      ]).asAssign(reference("response")))
      ..setElse(reference("JaguarResponse").newInstance(
          [reference("rawResponse")],
          constructor: "error").asAssign(reference("response")));
  }

  String toString() => 'JaguarHttpGenerator';
}
