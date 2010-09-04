Then /^(.+) should be in the (\d+)(?:st|nd|rd|th) position of the sprint named (.+)$/ do |story_subject, position, sprint_name|
  position = position.to_i
  story = Story.find(:first, :conditions => "subject='#{story_subject}'")
  sprint = Sprint.find(:first, :conditions => "name='#{sprint_name}'")
  stories = Story.find(:all, :conditions => "fixed_version_id=#{sprint.id}", :order => "position ASC")
  stories[position-1].should == story
end

Then /^I should see (\d+) sprint backlogs$/ do |count|
  sprint_backlogs = page.all(:css, ".sprint")
  sprint_backlogs.length.should == count.to_i
end

Then /^I should see the burndown chart$/ do
  page.should have_css("#burndown_#{@sprint.id.to_s}")
end

Then /^I should see the Issues page$/ do
  page.should have_css("#query_form")
end

Then /^I should see the taskboard$/ do
  page.should have_css('#taskboard')
end

Then /^I should see the product backlog$/ do
  page.should have_css('#product_backlog')
end

Then /^show me the list of sprints$/ do
  sprints = Sprint.find(:all, :conditions => "project_id=#{@project.id}")

  puts "\n"
  puts "\t| #{'id'.ljust(3)} | #{'name'.ljust(18)} | #{'sprint_start_date'.ljust(18)} | #{'effective_date'.ljust(18)} | #{'updated_on'.ljust(20)}"
  sprints.each do |sprint|  
    puts "\t| #{sprint.id.to_s.ljust(3)} | #{sprint.name.to_s.ljust(18)} | #{sprint.sprint_start_date.to_s.ljust(18)} | #{sprint.effective_date.to_s.ljust(18)} | #{sprint.updated_on.to_s.ljust(20)} |"
  end
  puts "\n\n"
end

Then /^show me the list of stories$/ do
  stories = Story.find(:all, :conditions => "project_id=#{@project.id}", :order => "position ASC")
  subject_max = (stories.map{|s| s.subject} << "subject").sort{|a,b| a.length <=> b.length}.last.length
  sprints = @project.versions.find(:all)
  sprint_max = (sprints.map{|s| s.name} << "sprint").sort{|a,b| a.length <=> b.length}.last.length

  puts "\n"
  puts "\t| #{'id'.ljust(3)} | #{'position'.ljust(8)} | #{'status'.ljust(12)} | #{'assignee'.ljust(12)} | #{'subject'.ljust(subject_max)} | #{'sprint'.ljust(sprint_max)} |"
  stories.each do |story|
    puts "\t| #{story.id.to_s.ljust(3)} | #{story.position.to_s.ljust(8)} | #{story.status.name[0,12].ljust(12)} | #{story.assigned_to.to_s[0,12].ljust(12)} | #{story.subject.ljust(subject_max)} | #{(story.fixed_version_id.nil? ? Sprint.new : Sprint.find(story.fixed_version_id)).name.ljust(sprint_max)} |"
  end
  puts "\n\n"
end

Then /^(.+) should be the higher item of (.+)$/ do |higher_subject, lower_subject|
  higher = Story.find(:all, :conditions => { :subject => higher_subject })
  higher.length.should == 1
  
  lower = Story.find(:all, :conditions => { :subject => lower_subject })
  lower.length.should == 1
  
  lower.first.higher_item.id.should == higher.first.id
end

Then /^the request should complete successfully$/ do
  page.driver.response.status.should == 200
end

Then /^the request should fail$/ do
  page.driver.response.status.should == 401
end

Then /^the (\d+)(?:st|nd|rd|th) story should be (.+)$/ do |position, subject|
  story = Story.find(:first, :conditions => "position=#{position}")
  story.should_not be_nil
  story.subject.should == subject
end

Then /^the (\d+)(?:st|nd|rd|th) position should be unique$/ do |position|
  Story.find(:all, :conditions => "position=#{position}").length.should == 1
end

Then /^the (\d+)(?:st|nd|rd|th) task for (.+) should be (.+)$/ do |position, story_subject, task_subject|
  story = Story.find(:first, :conditions => "subject='#{story_subject}'")
  story.children[position.to_i - 1].subject.should == task_subject
end

Then /^the server should return an update error$/ do
  page.driver.response.status.should == 400
end

Then /^the server should return (\d+) updated (.+)$/ do |count, object_type|
  page.all("##{object_type.pluralize} .#{object_type.singularize}").length.should == count.to_i
end

Then /^the sprint named (.+) should have (\d+) impediments? named (.+)$/ do |sprint_name, count, impediment_subject|
  sprints = Sprint.find(:all, :conditions => { :name => sprint_name })
  sprints.length.should == 1
  
  sprints.first.impediments.map{ |i| i.subject==impediment_subject}.length.should == count.to_i
end

Then /^the sprint should be updated accordingly$/ do
  sprint = Sprint.find(@sprint_params['id'])
  
  sprint.attributes.each_key do |key|
    unless ['updated_on', 'created_on'].include?(key)
      (key.include?('_date') ? sprint[key].strftime("%Y-%m-%d") : sprint[key]).should == @sprint_params[key]
    end
  end
end

Then /^the status of the story should be set as (.+)$/ do |status|
  @story.reload
  @story.status.name.downcase.should == status
end

Then /^the story named (.+) should have (\d+) task named (.+)$/ do |story_subject, count, task_subject|
  stories = Story.find(:all, :conditions => { :subject => story_subject })
  stories.length.should == 1
  
  tasks = Task.find(:all, :conditions => { :parent_id => stories.first.id })
  tasks.length.should == 1
  
  tasks.first.subject.should == task_subject
end

Then /^the story should be at the (top|bottom)$/ do |position|
  if position == 'top'
    @story.position.should == 1
  else
    @story.position.should == @story_ids.length
  end
end

Then /^the story should have a (.+) of (.+)$/ do |attribute, value|
  @story.reload
  if attribute=="tracker"
    attribute="tracker_id"
    value = Tracker.find(:first, :conditions => "name='#{value}'").id
  elsif attribute=="position"
    value = value.to_i
  end
  @story[attribute].should == value
end

Then /^the wiki page (.+) should contain (.+)$/ do |title, content|
  title = Wiki.titleize(title)
  page = @project.wiki.find_page(title)
  page.should_not be_nil

  raise "\"#{content}\" not found on page \"#{title}\"" unless page.content.text.match(/#{content}/) 
end