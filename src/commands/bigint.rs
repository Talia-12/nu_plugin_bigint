use std::str::FromStr;

use nu_plugin::{EngineInterface, EvaluatedCall, SimplePluginCommand};
use nu_protocol::{Category, Example, LabeledError, Signature, Value};
use rug::Integer;

use crate::{BigIntValue, BigintPlugin};

pub struct Bigint;

	impl SimplePluginCommand for Bigint {
	type Plugin = BigintPlugin;

	fn name(&self) -> &str {
		"bigint"
	}

	fn signature(&self) -> Signature {
		Signature::build(self.name())
			.category(Category::Experimental)
	}

	fn usage(&self) -> &str {
		"Given a string or number, returns the bigint equivalent of that string."
	}

	fn examples(&self) -> Vec<Example> {
		vec![
			Example {
				example: "\"64321979132594643297432\" | bigint",
				description: "Convert a large number represented as a string to a bigint.",
				result: Some(Value::test_custom_value(Box::new(BigIntValue { integer: Integer::from_str("64321979132594643297432").unwrap() }))),
			},
		]
	}

	fn run(
		&self,
		_plugin: &BigintPlugin,
		_engine: &EngineInterface,
		call: &EvaluatedCall,
		input: &Value,
	) -> Result<Value, LabeledError> {
		let span = input.span();

		match input {
			Value::String { val, .. } => BigIntValue::from_string(val).map(|bigint| {
				Value::custom(Box::new(bigint), span)
			}).map_err(|err| {
					LabeledError::new("Expected a string which is parseable as a bigint").with_label(
						format!("An error occurred parsing this: {}", err), 
						call.head
					)
				}),
			Value::Int { val, .. } => Ok(Value::custom(Box::new(BigIntValue::from_i64(*val)), span)),
			_ => Err(LabeledError::new("Expected String or Int input from pipeline").with_label(
				format!("requires String or Int input; got {}", input.get_type()),
				call.head
			))
		}
	}
}

#[test]
fn test_examples() -> Result<(), nu_protocol::ShellError> {
	use nu_plugin_test_support::PluginTest;

	// This will automatically run the examples specified in your command and compare their actual
	// output against what was specified in the example.
	//
	// We recommend you add this test to any other commands you create, or remove it if the examples
	// can't be tested this way.

	PluginTest::new("bigint", BigintPlugin.into())?
		.test_command_examples(&Bigint)
}
