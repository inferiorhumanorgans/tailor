require 'ripper'
require_relative '../../../spec_helper'
require 'tailor/rulers/indentation_spaces_ruler/indentation_manager'


describe Tailor::Rulers::IndentationSpacesRuler::IndentationManager do
  let!(:spaces) { 5 }
  let!(:lexed_line) { double "LexedLine" }

  before do
    Tailor::Logger.stub(:log)
    subject.instance_variable_set(:@spaces, spaces)
  end

  subject do
    Tailor::Rulers::IndentationSpacesRuler::IndentationManager.new spaces
  end

  describe "#should_be_at" do
    it "returns @proper[:this_line]" do
      subject.instance_variable_set(:@proper, { this_line: 321 })
      subject.should_be_at.should == 321
    end
  end

  describe "#decrease_this_line" do
    let!(:spaces) { 27 }

    context "#started? is true" do
      before { subject.stub(:started?).and_return true }

      context "@proper[:this_line] gets decremented < 0" do
        it "sets @proper[:this_line] to 0" do
          subject.instance_variable_set(:@proper, {
            this_line: 0, next_line: 0
          })

          subject.decrease_this_line
          proper_indentation = subject.instance_variable_get(:@proper)
          proper_indentation[:this_line].should == 0
        end
      end

      context "@proper[:this_line] NOT decremented < 0" do
        it "decrements @proper[:this_line] by @spaces" do
          subject.instance_variable_set(:@proper, {
            this_line: 28, next_line: 28
          })
          subject.decrease_this_line

          proper_indentation = subject.instance_variable_get(:@proper)
          proper_indentation[:this_line].should == 1
        end
      end
    end

    context "#started? is false" do
      before { subject.stub(:started?).and_return false }

      it "does not decrement @proper[:this_line]" do
        subject.instance_variable_set(:@proper, {
          this_line: 28, next_line: 28
        })
        subject.decrease_this_line

        proper_indentation = subject.instance_variable_get(:@proper)
        proper_indentation[:this_line].should == 28
      end
    end
  end

  describe "#set_up_line_transition" do
    context "@amount_to_change_this < 0" do
      before { subject.instance_variable_set(:@amount_to_change_this, -1) }

      it "should call #decrease_this_line" do
        subject.should_receive(:decrease_this_line)
        subject.set_up_line_transition
      end
    end
  end

  describe "#transition_lines" do
    context "#started? is true" do
      before { subject.stub(:started?).and_return true }

      it "sets @proper[:this_line] to @proper[:next_line]" do
        subject.instance_variable_set(:@proper, { next_line: 33 })

        expect { subject.transition_lines }.to change{subject.should_be_at}.
          from(subject.should_be_at).to(33)
      end
    end

    context "#started? is false" do
      before { subject.stub(:started?).and_return false }

      it "sets @proper[:this_line] to @proper[:next_line]" do
        subject.instance_variable_set(:@proper, { next_line: 33 })
        expect { subject.transition_lines }.to_not change{subject.should_be_at}
      end
    end
  end

  describe "#start" do
    it "sets @do_measurement to true" do
      subject.instance_variable_set(:@do_measurement, false)
      subject.start
      subject.instance_variable_get(:@do_measurement).should be_true
    end
  end

  describe "#stop" do
    it "sets @do_measurement to false" do
      subject.instance_variable_set(:@do_measurement, true)
      subject.stop
      subject.instance_variable_get(:@do_measurement).should be_false
    end
  end

  describe "#started?" do
    context "@do_measurement is true" do
      before { subject.instance_variable_set(:@do_measurement, true) }
      specify { subject.started?.should be_true }
    end

    context "@do_measurement is false" do
      before { subject.instance_variable_set(:@do_measurement, false) }
      specify { subject.started?.should be_false }
    end
  end

  describe "#update_actual_indentation" do
    context "lexed_line_output.end_of_multi_line_string? is true" do
      before do
        lexed_line.stub(:end_of_multi_line_string?).and_return true
      end

      it "returns without updating @actual_indentation" do
        lexed_line.should_not_receive(:first_non_space_element)
        subject.update_actual_indentation(lexed_line)
      end
    end

    context "lexed_line_output.end_of_multi_line_string? is false" do
      before do
        lexed_line.stub(:end_of_multi_line_string?).and_return false
        lexed_line.stub(:first_non_space_element).
          and_return first_non_space_element
      end

      context "when indented" do
        let(:first_non_space_element) do
          [[1, 5], :on_comma, ',']
        end

        it "returns the column value of that element" do
          subject.update_actual_indentation(lexed_line)
          subject.instance_variable_get(:@actual_indentation).should == 5
        end
      end

      context "when not indented" do
        let(:first_non_space_element) do
          [[1, 0], :on_kw, 'class']
        end

        it "returns the column value of that element" do
          subject.update_actual_indentation(lexed_line)
          subject.instance_variable_get(:@actual_indentation).should == 0
        end
      end
    end
  end

  describe "#line_ends_with_single_token_indenter?" do
    context "lexed_line doesn't end with an op, comma, period, label, or kw" do
      before do
        lexed_line.stub(ends_with_op?: false)
        lexed_line.stub(ends_with_comma?: false)
        lexed_line.stub(ends_with_period?: false)
        lexed_line.stub(ends_with_label?: false)
        lexed_line.stub(ends_with_modifier_kw?: false)
      end

      specify do
        subject.line_ends_with_single_token_indenter?(lexed_line).
          should be_false
      end
    end

    context "lexed_line ends with an op" do
      before do
        lexed_line.stub(ends_with_op?: true)
        lexed_line.stub(ends_with_comma?: false)
        lexed_line.stub(ends_with_period?: false)
        lexed_line.stub(ends_with_label?: false)
        lexed_line.stub(ends_with_modifier_kw?: false)
      end

      specify do
        subject.line_ends_with_single_token_indenter?(lexed_line).should be_true
      end
    end

    context "lexed_line ends with a comma" do
      before do
        lexed_line.stub(ends_with_op?: false)
        lexed_line.stub(ends_with_comma?: true)
        lexed_line.stub(ends_with_period?: false)
        lexed_line.stub(ends_with_label?: false)
        lexed_line.stub(ends_with_modifier_kw?: false)
      end

      specify do
        subject.line_ends_with_single_token_indenter?(lexed_line).should be_true
      end
    end

    context "lexed_line ends with a period" do
      before do
        lexed_line.stub(ends_with_op?: false)
        lexed_line.stub(ends_with_comma?: false)
        lexed_line.stub(ends_with_period?: true)
        lexed_line.stub(ends_with_label?: false)
        lexed_line.stub(ends_with_modifier_kw?: false)
      end

      specify do
        subject.line_ends_with_single_token_indenter?(lexed_line).should be_true
      end
    end

    context "lexed_line ends with a label" do
      before do
        lexed_line.stub(ends_with_op?: false)
        lexed_line.stub(ends_with_comma?: false)
        lexed_line.stub(ends_with_period?: false)
        lexed_line.stub(ends_with_label?: true)
        lexed_line.stub(ends_with_modifier_kw?: false)
      end

      specify do
        subject.line_ends_with_single_token_indenter?(lexed_line).should be_true
      end
    end

    context "lexed_line ends with a modified kw" do
      before do
        lexed_line.stub(ends_with_op?: false)
        lexed_line.stub(ends_with_comma?: false)
        lexed_line.stub(ends_with_period?: false)
        lexed_line.stub(ends_with_label?: false)
        lexed_line.stub(ends_with_modifier_kw?: true)
      end

      specify do
        subject.line_ends_with_single_token_indenter?(lexed_line).should be_true
      end
    end
  end

  describe "#line_ends_with_same_as_last" do
    context "@indent_reasons is empty" do
      before do
        subject.instance_variable_set(:@indent_reasons, [])
      end

      it "returns false" do
        subject.line_ends_with_same_as_last([]).should be_false
      end
    end

    context "@indent_reasons.last[:token] != token_event.last" do
      let(:last_single_token) { [[1, 2], :on_comma, ','] }

      before do
        subject.instance_variable_set(:@indent_reasons,
          [{ event_type: :on_op }])
      end

      it "returns false" do
        subject.line_ends_with_same_as_last(last_single_token).should be_false
      end
    end

    context "@indent_reasons.last[:token] == token_event.last" do
      let(:last_single_token) { [[1, 2], :on_comma, ','] }

      before do
        subject.instance_variable_set(:@indent_reasons,
          [{ event_type: :on_comma }])
      end

      it "returns true" do
        subject.line_ends_with_same_as_last(last_single_token).should be_true
      end
    end
  end

  describe "#multi_line_parens?" do
    context "an unclosed ( exists on the previous line" do
      context "an unclosed ( does not exist on the current line" do
        before do
          d_tokens = [{ token: '(', lineno: 1 }]
          subject.instance_variable_set(:@indent_reasons, d_tokens)
        end

        it "returns true" do
          subject.multi_line_parens?(2).should be_true
        end
      end

      context "an unclosed ( exists on the current line" do
        before do
          d_tokens = [{ token: '(', lineno: 1 }, { token: '(', lineno: 2 }]
          subject.instance_variable_set(:@indent_reasons, d_tokens)
        end

        it "returns true" do
          subject.multi_line_parens?(2).should be_false
        end
      end
    end

    context "an unclosed ( does not exist on the previous line" do
      before do
        d_tokens = [{ token: '(', lineno: 1 }]
        subject.instance_variable_set(:@indent_reasons, d_tokens)
      end

      it "returns true" do
        subject.multi_line_parens?(1).should be_false
      end
    end
  end

  describe "#last_opening_event" do
    context "@indent_reasons is empty" do
      before { subject.instance_variable_set(:@indent_reasons, []) }
      specify { subject.last_opening_event(nil).should be_nil }
    end

    context "@indent_reasons contains the corresponding opening event" do
      let(:indent_reasons) do
        [{ event_type: :on_lparen }, { event_type: :on_lbrace }]
      end

      before { subject.instance_variable_set(:@indent_reasons, indent_reasons) }

      context "the corresponding opening event is last" do
        it "returns the matching opening event" do
          subject.last_opening_event(:on_rbrace).should == indent_reasons.last
        end
      end

      context "the corresponding opening event is not last" do
        it "returns the matching opening event" do
          subject.last_opening_event(:on_rparen).should == indent_reasons.first
        end
      end
    end
  end

  describe "#remove_continuation_keywords" do
    before do
      subject.instance_variable_set(:@indent_reasons, indent_reasons)
    end

    context "@indent_reasons is empty" do
      let(:indent_reasons) do
        i = double "@indent_reasons"
        i.stub_chain(:last, :[]).and_return []
        i.stub(:empty?).and_return true

        i
      end

      specify { subject.remove_continuation_keywords.should be_nil }
    end

    context "@indent_reasons does not contain CONTINUATION_KEYWORDS" do
      let(:indent_reasons) do
        i = double "@indent_reasons"
        i.stub_chain(:last, :[]).and_return [{ token: 'if' }]
        i.stub(:empty?).and_return false

        i
      end

      it "should not call #pop on @indent_reasons" do
        indent_reasons.should_not_receive(:pop)
        subject.remove_continuation_keywords
      end
    end

    context "@indent_reasons contains CONTINUATION_KEYWORDS" do
      let(:indent_reasons) do
        [{ token: 'if' }, { token: 'elsif' }]
      end

      it "should call #pop on @indent_reasons one time" do
        subject.instance_variable_set(:@indent_reasons, indent_reasons)
        subject.remove_continuation_keywords
        subject.instance_variable_get(:@indent_reasons).should ==
          [{ token: 'if' }]
      end
    end
  end
end
