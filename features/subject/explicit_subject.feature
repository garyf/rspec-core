Feature: Explicit Subject

  Use `subject` in the group scope to explicitly define the value that is
  returned by the `subject` method in the example scope.

  Note that while the examples below demonstrate how `subject` can be used as a
  user-facing concept, we recommend that you reserve it for support of custom
  matchers and/or extension libraries that hide its use from examples.

  A named `subject` improves on a bare `subject` by assigning it a contextually
  semantic name.

  Since a named `subject` is an explicit `subject`, it defines the value that is returned
  by the `subject` method in the example scope. Additionally, it defines a memoized
  helper method with the provided name. The value will be cached across multiple
  calls in the sample example but not across examples.

  Scenario: `subject` in top level group
    Given a file named "top_level_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some elements" do
        subject { [1,2,3] }
        it "should have the prescribed elements" do
          expect(subject).to eq([1,2,3])
        end
      end
      """
    When I run `rspec top_level_subject_spec.rb`
    Then the examples should all pass

  Scenario: `subject` in a nested group
    Given a file named "nested_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        subject { [1,2,3] }
        describe "with some elements" do
          it "should have the prescribed elements" do
            expect(subject).to eq([1,2,3])
          end
        end
      end
      """
    When I run `rspec nested_subject_spec.rb`
    Then the examples should all pass

  Scenario: Access `subject` from `before` block
    Given a file named "top_level_subject_spec.rb" with:
      """ruby
      RSpec.describe Array, "with some elements" do
        subject { [] }
        before { subject.push(1,2,3) }
        it "should have the prescribed elements" do
          expect(subject).to eq([1,2,3])
        end
      end
      """
    When I run `rspec top_level_subject_spec.rb`
    Then the examples should all pass

  Scenario: Invoke helper method from `subject` block
    Given a file named "helper_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        def prepared_array; [1,2,3] end
        subject { prepared_array }
        describe "with some elements" do
          it "should have the prescribed elements" do
            expect(subject).to eq([1,2,3])
          end
        end
      end
      """
    When I run `rspec helper_subject_spec.rb`
    Then the examples should all pass

  Scenario: `subject` block is invoked at most once per example
    Given a file named "nil_subject_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe "#[]" do
          context "with index out of bounds" do
            before { expect(Array).to receive(:one_two_three).once.and_return([1,2,3]) }
            subject { Array.one_two_three[42] }
            it { is_expected.to be_nil }
          end
        end
      end
      """
    When I run `rspec nil_subject_spec.rb`
    Then the examples should all pass

  Scenario: `subject!` bang method
    Given a file named "subject_bang_spec.rb" with:
      """ruby
      RSpec.describe Array do
        describe '#pop' do
          let(:prepared_array) { [1,2,3] }
          subject! { prepared_array.pop }
          it "removes the last value from the array" do
            expect(prepared_array).to eq([1,2])
          end
          it "returns the last value of the array" do
            expect(subject).to eq(3)
          end
        end
      end
      """
    When I run `rspec subject_bang_spec.rb`
    Then the examples should all pass

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

        it "is available as the bare `subject` as well" do
          expect(subject).to eq(3)
        end

        it "works with the one-liner syntax too" do
          is_expected.to eq(4)
        end
      end
      """
    When I run `rspec named_subject_spec.rb`
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

  Scenario: Using `subject(:name)1 does not allow `super` to be called
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
