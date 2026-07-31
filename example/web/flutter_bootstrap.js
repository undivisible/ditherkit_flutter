{{flutter_js}}
{{flutter_build_config}}

for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += '?shell=3';
  if (build.mainWasmPath) build.mainWasmPath += '?shell=3';
  if (build.jsSupportRuntimePath) build.jsSupportRuntimePath += '?shell=3';
}
_flutter.loader.load();
