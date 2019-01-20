install-dashboard: update-addUserToApache2Group
	modules/dashboard/dashboard.sh

install-pihole: update-addUserToApache2Group
	modules/pihole/pihole.sh

update-system:
	modules/systemUpdate/update.sh

update-addUserToApache2Group:
	modules/systemUpdate/addUserToApache2Group.sh
