//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <open_dir_linux/open_dir_linux_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) open_dir_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "OpenDirLinuxPlugin");
  open_dir_linux_plugin_register_with_registrar(open_dir_linux_registrar);
}
