shared_context "renderable view components" do
  let(:view_context) { controller.view_context }

  let(:render) do
    component.render_in(view_context).to_s
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive(:view_context).and_return(view_context)
  end
end