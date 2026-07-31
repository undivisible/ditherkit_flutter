{{flutter_js}}
{{flutter_build_config}}

for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += '?shell=4';
  if (build.mainWasmPath) build.mainWasmPath += '?shell=4';
  if (build.jsSupportRuntimePath) build.jsSupportRuntimePath += '?shell=4';
}
_flutter.loader.load();
