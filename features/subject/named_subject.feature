Feature: Named Subject

  A named `subject` improves on an [explicit `subject`](explicit-subject) by assigning it a contextually
  semantic name.

  Since a named `subject` is an explicit `subject`, it defines the value that is returned
  by the `subject` method in the example scope. Additionally, it defines a memoized
  helper method with the provided name. The value will be cached across multiple
  calls in the sample example but not across examples.

  Note that a named `subject` is lazy-evaluated: it is not evaluated until the first time
  either an explicit `subject` or the method it defines is invoked. You can use `subject!`
  to force the invocation before each example.

  A named `subject` is technically equivalent to:

  ```ruby
  let(:empty_array) { Array.new }
  subject { empty_array }
  ```

  The advantage of the named `subject` is it explicitly calls out the helper method
  definition as the object under test.

  Scenario: Use `subject(:name)` to define a memoized bareword
    **Note:** that while a global variable is used in the examples below, this
    behavior is strongly discouraged in actual specs. It is used here simply
    to demonstrate the non-cached memoized behavior.
    Given a file named "named_subject_spec.rb" with:
      """ruby
      $count = 0
      RSpec.describe "named subject" do
        subject(:global_count) { $count += 1 }

        it "memoizes the value" do
          expect(global_count).to eq(1)
          expect(global_count).to eq(1)
          expect(subject).to eq(1)
          is_expected.to eq(1)
        end

        it "is not cached across examples" do
          expect(global_count).to eq(2)
          expect(subject).to eq(2)
          is_expected.to eq(2)
        end
      end
      """
    When I run `rspec named_subject_spec.rb`
    Then the examples should all pass

  Scenario: Access to the explicit `subject` is still available
    **Note:** that while the example below demonstrates how an explicit `subject` can
    still be used. We recommend that you reserve it for use in [`shared_examples`](docs/example-groups/shared-examples),
    custom matchers and/or extension libraries that hide its use from examples.
    Given a file named "explicit_named_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some fibonacci elements" do
        subject(:finite_fibonacci_sequence) { [1, 1, 2, 3, 5] }

        it "has the first five numbers in the sequence" do
          expect(subject).to eq([1, 1, 2, 3, 5])
        end
      end
      """
    When I run `rspec explicit_named_subject_spec.rb`
    Then the examples should all pass

  Scenario: Available to the one-liner syntax
    For more information see the [one-liner syntax](docs/subject/one-liner-syntax).
    Given a file named "one_liner_named_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some fibonacci elements" do
        subject(:finite_fibonacci_sequence) { [1, 1, 2, 3, 5] }

        it "has the first five numbers in the sequence" do
          is_expected.to eq([1, 1, 2, 3, 5])
        end
      end
      """
    When I run `rspec one_liner_named_subject_spec.rb`
    Then the examples should all pass

  Scenario: Available in a nested group
    Given a file named "nested_named_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        subject(:finite_fibonacci_sequence) { [1, 1, 2, 3, 5] }

        context "with some fibonacci elements" do
          it "has the first five numbers in the sequence" do
            is_expected.to eq([1, 1, 2, 3, 5])
          end
        end
      end
      """
    When I run `rspec nested_named_subject_spec.rb`
    Then the examples should all pass

  Scenario: Available from `before` hooks
    Given a file named "named_subject_before_hook_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some fibonacci elements" do
        subject(:finite_fibonacci_sequence) { Array.new }

        before do
          finite_fibonacci_sequence.push(1, 1, 2, 3, 5)
        end

        it "has the first five numbers in the sequence" do
          expect(finite_fibonacci_sequence).to eq([1, 1, 2, 3, 5])
        end
      end
      """
    When I run `rspec named_subject_before_hook_spec.rb`
    Then the examples should all pass

  Scenario: Invoke helper method from named `subject` definition
    Given a file named "helper_named_subject_spec.rb" with:
      """ruby
      FibonacciGenerator = Enumerator.new do |seq|
        a = b = 1
        loop do
          seq << a
          a, b = b, a + b
        end
      end

      RSpec.describe Array do
        def prepare_sequence(n)
          FibonacciGenerator.take(n)
        end

        context "with some fibonacci elements" do
          subject(:finite_fibonacci_sequence) { prepare_sequence(5) }

          it "has the first five numbers in the sequence" do
            expect(finite_fibonacci_sequence).to eq([1, 1, 2, 3, 5])
          end
        end
      end
      """
    When I run `rspec helper_named_subject_spec.rb`
    Then the examples should all pass

  Scenario: Use `subject!(:name)` to define a memoized bareword that is called in a `before` hook
    Given a file named "named_subject_bang_spec.rb" with:
      """ruby
      RSpec.describe "named subject!" do
        let(:invocation_order) { [] }

        subject!(:finite_fibonacci_sequence) do
          invocation_order << :subject!
          [1, 1, 2, 3, 5]
        end

        it "calls the bareword in a before hook" do
          invocation_order << :example
          expect(invocation_order).to eq([:subject!, :example])
        end

        it "sets the subject as expected" do
          expect(finite_fibonacci_sequence).to eq([1, 1, 2, 3, 5])
        end
      end
      """
    When I run `rspec named_subject_bang_spec.rb`
    Then the examples should all pass

  Scenario: Does not allow `super` to be called
    Given a file named "super_named_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some fibonacci elements" do
        subject(:finite_fibonacci_sequence) { [1, 1, 2, 3, 5] }

        context "with more numbers" do
          subject(:finite_fibonacci_sequence) { super().push(8, 13) }

          it "has the first seven numbers in the sequence" do
            expect(finite_fibonacci_sequence).to eq([1, 1, 2, 3, 5, 8, 13])
          end
        end
      end
      """
    When I run `rspec super_named_subject_spec.rb`
    Then the examples should all fail
    And the output should contain "`super` in named subjects is not supported"
