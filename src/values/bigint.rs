use nu_protocol::{ast, CustomValue, ShellError, Span, Value};
use rug::{integer::ParseIntegerError, ops::*, Integer};
use serde::{Deserialize, Serialize};
use std::{cmp::Ordering, ops::*, str::FromStr};

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct BigIntValue {
	pub(crate) integer: Integer,
}

impl BigIntValue {
	pub fn from_string(s: &str) -> Result<Self, ParseIntegerError> {
		let integer = Integer::from_str(s)?;
		Ok(BigIntValue { integer })
	}

	pub fn from_i64(i: i64) -> Self {
		BigIntValue { integer: i.into() }
	}
}

impl<'a> Add for &'a BigIntValue {
    type Output = BigIntValue;

    fn add(self, rhs: Self) -> Self::Output {
        
				let mut integer = rhs.integer.clone();
				integer.add_from(self.integer.clone());
			BigIntValue { integer }
    }
}

impl<'a> Sub for &'a BigIntValue {
    type Output = BigIntValue;

    fn sub(self, rhs: Self) -> Self::Output {
        
				let mut integer = rhs.integer.clone();
				integer.sub_from(self.integer.clone());
			BigIntValue { integer }
    }
}

impl<'a> Mul for &'a BigIntValue {
    type Output = BigIntValue;

    fn mul(self, rhs: Self) -> Self::Output {
        
				let mut integer = rhs.integer.clone();
				integer.mul_from(self.integer.clone());
			BigIntValue { integer }
    }
}

#[typetag::serde]
impl CustomValue for BigIntValue {
	fn clone_value(&self, span: Span) -> Value {
		Value::custom(Box::new(self.clone()), span)
	}

	fn type_name(&self) -> String {
		return "bigint".to_string()
	}

	fn to_base_value(&self, span: Span) -> Result<Value, ShellError> {
		Ok(Value::string(self.integer.to_string(), span))
	}

	fn partial_cmp(&self, other: &Value) -> Option<Ordering> {
    if let Value::Custom { val, .. } = other {
    	val.as_any()
				.downcast_ref()
    		.and_then(|other: &BigIntValue| PartialOrd::partial_cmp(self, other))
    } else {
    	None
    }
  }

  fn operation(
  	&self,
  	lhs_span: Span,
  	operator: ast::Operator,
  	op_span: Span,
  	right: &Value,
  ) -> Result<Value, ShellError> {
		if let Some(right) = right
			.as_custom_value()
			.ok()
			.and_then(|c| c.as_any().downcast_ref::<BigIntValue>())
		{
			match operator {
	  		ast::Operator::Math(ast::Math::Plus) => Ok(Value::custom(
					Box::new(self + right), op_span
				)),
				ast::Operator::Math(ast::Math::Minus) => Ok(Value::custom(
					Box::new(self - right), op_span
				)),
				ast::Operator::Math(ast::Math::Multiply) => Ok(Value::custom(
					Box::new(self * right), op_span
				)),
	  		_ => Err(ShellError::UnsupportedOperator { operator, span: op_span }),
  		}
		}
		else {
			match operator {
	  		ast::Operator::Math(ast::Math::Plus) |
	  		ast::Operator::Math(ast::Math::Minus) |
	  		ast::Operator::Math(ast::Math::Multiply) => Err(ShellError::OperatorMismatch {
					op_span,
					lhs_ty: self.typetag_name().into(),
					lhs_span,
					rhs_ty: right.get_type().to_string(),
					rhs_span: right.span(),
				}),
	  		_ => Err(ShellError::UnsupportedOperator { operator, span: op_span }),
  		}
		}  	
	}

  fn as_any(&self) -> &dyn std::any::Any {
  	self
  }

  fn as_mut_any(&mut self) -> &mut dyn std::any::Any {
  	self
  }
}
