use nu_plugin::{EngineInterface, EvaluatedCall, SimplePluginCommand};
use nu_protocol::{Category, Example, LabeledError, Signature, SyntaxShape, Value};

use crate::BigintPlugin;

pub struct Bigint;

impl SimplePluginCommand for Bigint {
    type Plugin = BigintPlugin;

    fn name(&self) -> &str {
        "bigint"
    }

    fn signature(&self) -> Signature {
        Signature::build(self.name())
            .required("name", SyntaxShape::String, "(FIXME) A demo parameter - your name")
            .switch("shout", "(FIXME) Yell it instead", None)
            .category(Category::Experimental)
    }

    fn usage(&self) -> &str {
        "(FIXME) help text for bigint"
    }

    fn examples(&self) -> Vec<Example> {
        vec![
            Example {
                example: "bigint Ellie",
                description: "Say hello to Ellie",
                result: Some(Value::test_string("Hello, Ellie. How are you today?")),
            },
            Example {
                example: "bigint --shout Ellie",
                description: "Shout hello to Ellie",
                result: Some(Value::test_string("HELLO, ELLIE. HOW ARE YOU TODAY?")),
            },
        ]
    }

    fn run(
        &self,
        _plugin: &BigintPlugin,
        _engine: &EngineInterface,
        call: &EvaluatedCall,
        _input: &Value,
    ) -> Result<Value, LabeledError> {
        let name: String = call.req(0)?;
        let mut greeting = format!("Hello, {name}. How are you today?");
        if call.has_flag("shout")? {
            greeting = greeting.to_uppercase();
        }
        Ok(Value::string(greeting, call.head))
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
