require 'excon'
require 'ostruct'

CONFIG = OpenStruct.new
optional_envs = %w(DOVETAIL_PROD_HOST)

# load env config
File.open("#{File.dirname(__FILE__)}/../../env-example", 'r').each_line do |line|
  unless line.strip.empty? || line[0] == '#'

    name = line.split('=').first
    CONFIG[name] = ENV[name] unless ENV[name].nil? || ENV[name].empty?
    abort "you must set #{name}" unless CONFIG[name] || optional_envs.include?(name)

    # add scheme and check connection to hosts
    if CONFIG[name] && name.match(/_HOST$/)
      if CONFIG[name][0..3] != 'http'
        is_prx = CONFIG[name].match(/.*\.prxu?\.(?:org|tech)$/)
        is_aws = CONFIG[name].match(/.*\.amazonaws\./)
        scheme = is_prx || is_aws ? 'https' : 'http'
        CONFIG[name] = "#{scheme}://#{CONFIG[name]}"
      end
      begin
        Excon.head(CONFIG[name])
      rescue
        abort "unable to connect to #{name} = #{CONFIG[name]}"
      end
    end
  end
end
