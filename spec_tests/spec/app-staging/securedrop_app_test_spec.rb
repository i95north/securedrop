# these checks are for the role `app-test`,
# which is different from simply `app`, which
# is tested in `securedrop_app_spec.rb`.


# ensure logging is enabled for source interface in staging
describe file('/var/www/source.wsgi') do
  it { should be_file }
  it { should be_owned_by 'www-data' }
  it { should be_grouped_into 'www-data' }
  it { should be_mode '640' }
  its(:content) { should match /^import logging$/ }
  its(:content) { should match /^logging\.basicConfig\(stream=sys\.stderr\)$/ }
end

# ensure app-armor profiles are in complain mode for staging
# there are two profiles that should be in complain mode:
# - usr.sbin.apache2
# - usr.sbin.tor
describe command('aa-status') do
  expected_output = <<-eos
2 profiles are in complain mode.
   /usr/sbin/apache2
   /usr/sbin/tor
eos
  its(:stdout) { should contain(expected_output) }
end

# declare required pip dependencies.
# these checks explicitly reference version number
# to make sure the stack and tests are in sync.
pip_dependencies = [
  'Flask-Testing==0.4.2',
  'mock==1.0.1',
  'pytest==2.6.4',
  'selenium==2.44.0',
]
# ensure pip depdendencies are installed in staging.
# these are required for running unit and functional tests
describe command('pip freeze') do
  pip_dependencies.each do |pip_dependency|
    its(:stdout) { should contain(pip_dependency) }
  end
end

# declare apt package dependencies for running tests
apt_dependencies = [
  'firefox',
  'xvfb',
]
# ensure apt package dependencies are installed
apt_dependencies.each do |apt_dependency|
  describe package(apt_dependency) do
    it { should be_installed }
  end
end

# ensure xvfb service config is present
describe file('/etc/init.d/xvfb') do
  it { should be_file }
  it { should be_mode '700' }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  xvfb_init_content = <<-eos
# This is the /etc/init.d/xvfb script. We use it to launch xvfb at boot in the
# development environment so we can easily run the functional tests.

XVFB=/usr/bin/Xvfb
XVFBARGS=":1 -screen 0 1024x768x24 -ac +extension GLX +render -noreset"
PIDFILE=/var/run/xvfb.pid
case "$1" in
  start)
    echo -n "Starting virtual X frame buffer: Xvfb"
    start-stop-daemon --start --quiet --pidfile $PIDFILE --make-pidfile --background --exec $XVFB -- $XVFBARGS
    echo "."
    ;;
  stop)
    echo -n "Stopping virtual X frame buffer: Xvfb"
    start-stop-daemon --stop --quiet --pidfile $PIDFILE
    echo "."
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  *)
        echo "Usage: /etc/init.d/xvfb {start|stop|restart}"
        exit 1
esac

exit 0
eos
  its(:content) { should eq xvfb_init_content }
end




