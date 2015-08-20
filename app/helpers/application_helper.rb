module ApplicationHelper
  def restricted?
    if controller.class.respond_to? :restricted?
      controller.class.restricted?
    else
      action_name.eql? 'restricted'
    end
  end
end
