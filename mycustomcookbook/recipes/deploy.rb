
# restart apache and tomcat for fun
execute 'restart tomcat' do
  command "service tomcat#{node['tomcat']['base_version']} restart"
end

execute 'restart httpd' do
  command "service httpd restart"
end

# set up the railo configuration
include_recipe 'mycustomcookbook::configure_railo'

node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'java'
    Chef::Log.debug("Skipping deploy::java application #{application} as it is not a Java app")
    next
  end

  if deploy[:mycustomcookbook] == false
    Chef::Log.debug("Skipping deploy::java application #{application} as it is not a mycustomcookbook app")
    next
  end

  # set up the apache rewrites
  config_dir = "#{node[:apache][:dir]}/sites-available/#{application}.conf.d/rewrite"
  directory config_dir do
    recursive true
  end

  template "#{config_dir}/custom_rewrites.conf" do
    mode 0644
    source 'apache_rewrites.erb'
    variables({
      :deploy => deploy
    })
  end

  # configure mycustomcookbook write-required folders ( based off hgignore and /newInstall/index.php )
  [
    "/site_assets/cache",
    "/scheduled_tasks/output",
    "/data",
    "/portal/temp",
    "/temp",
    "/portal/audit/processors",
    "/portal/privilages/processors",
    "/list_files"
  ].each do |writableFolder|
    directory "#{deploy[:absolute_document_root]}#{writableFolder}" do
      owner "#{node[:railo][:user][:id]}"
      group "#{node[:railo][:user][:id]}"
      mode "0755"
      recursive true
    end
  end

  # configure mycustomcookbook write-required files
  [
    "/sitemap.xml",
    "/robots.txt"
  ].each do |writablePath|
    file "#{deploy[:absolute_document_root]}#{writablePath}" do
      action :create
      owner "#{node[:railo][:user][:id]}"
      group "#{node[:railo][:user][:id]}"
      mode "0755"
    end
  end

  # install node scripts and do a gulp
  execute "npm install" do
    cwd "#{deploy[:absolute_document_root]}"
  end
  execute "gulp" do
    cwd "#{deploy[:absolute_document_root]}"
  end
  
end

# restart apache and tomcat for fun
execute 'restart tomcat' do
  command "service tomcat#{node['tomcat']['base_version']} restart"
end

execute 'restart httpd' do
  command "service httpd restart"
end




