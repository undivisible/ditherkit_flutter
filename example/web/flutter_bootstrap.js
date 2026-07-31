{{flutter_js}}
{{flutter_build_config}}

for (const build of _flutter.buildConfig.builds) {
  if (build.mainJsPath) build.mainJsPath += '?shell=5';
  if (build.mainWasmPath) build.mainWasmPath += '?shell=5';
  if (build.jsSupportRuntimePath) build.jsSupportRuntimePath += '?shell=5';
}
_flutter.loader.load();
