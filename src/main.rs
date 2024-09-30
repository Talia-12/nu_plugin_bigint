use nu_plugin::{MsgPackSerializer, Plugin, PluginCommand, serve_plugin};

mod commands;
mod values;
pub use commands::*;
pub use values::*;

pub struct BigintPlugin;

impl Plugin for BigintPlugin {
	fn version(&self) -> String {
		// This automatically uses the version of your package from Cargo.toml as the plugin version
		// sent to Nushell
		env!("CARGO_PKG_VERSION").into()
	}

	fn commands(&self) -> Vec<Box<dyn PluginCommand<Plugin = Self>>> {
		vec![
			// Commands should be added here
			Box::new(Bigint),
		]
	}
}

fn main() {
	serve_plugin(&BigintPlugin, MsgPackSerializer);
}
