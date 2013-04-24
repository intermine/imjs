# A file that solely exists to provide type definitions
# for documentation generation.

# The interface of objects that can be contained within a {Query}'s constraints array.
class Contraint

  # @property [String] The path that this constraint constrains.
  path: ''

# A constraint that expresses the limitation that a path be limited to only
# members of a sub-type of the natural type of this path.
class SubTypeConstraint extends Constraint

  # @property [String] The type that this path is constrained to.
  type: ''

# A constraint that expresses the action of an operator over a path.
class OperatorConstraint extends Constraint

  # @property [String] The operator for this constraint.
  op: ''

  # @property [String] An identifier used in logic expressions
  code: ''

# A constraint that associates a path with value, within the context of an operation.
class ValueConstraint extends OperatorConstraint

  # @property [String, Number] The value to associate with the path.
  value: ''

  # @property [String] A disambiguating value used by some operations.
  extraValue: ''

# A constraint that associates a path with a set of values within the context of an operation.
class MultiValueConstraint extends OperatorConstraint

  # @property [Array<String>] A set of values to associate with the path.
  values: []

# A contraint that asserts a path represents one of the objects with the given ids.
class IdsContraint extends OperatorConstraint

  # @property [Array<Integer>] The ids the object must have.
  ids: []

