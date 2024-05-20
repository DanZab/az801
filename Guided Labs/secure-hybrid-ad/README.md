# Secure a hybrid Active Directory infrastructure 
Back to [Guided Labs](https://github.com/DanZab/az801/tree/main/Guided%20Labs) index.

**Exam Objectives**
- Configure password policies
	- Default Domain Policy
	- Password Settings Object
- Enable password block lists
- Manage protected users
- Manage account security on an RODC
- Harden domain controllers
- Configure authentication policy silos
- Restrict access to domain controllers
- Configure account security
- Manage AD built-in administrative groups
- Manage AD delegation
- Implement and manage Microsoft Defender for Identity

**Videos**
- [AZ-801 Secure AD (1/7): Password Policies](https://youtu.be/9SenazZr7kw)
- [AZ-801 Secure AD (2/7): Manage Built-In Admin Groups](https://youtu.be/iuNaV4xlrRc)
- [AZ-801 Secure AD (3/7): AD Delegation](https://youtu.be/zwhMyELTH0Q)
- [AZ-801 Secure AD (4/7): Protected Users](https://youtu.be/5jdYDLM2fBo)
- [AZ-801 Secure AD (5/7): Authentication Policies and Silos](https://youtu.be/6clJfHTmi2Q)
- [AZ-801 Secure AD (6/7): Managing RODCs - Part 1](https://youtu.be/HiSDElIBg44)
- [AZ-801 Secure AD (7/7): Managing RODCs - Part 2](https://youtu.be/8_4Wqz-3IK8)

## Lab Setup
You can use the default lab configuration for most content:
- Domain Controller (AD-P1)
- Management Server (MGMT-P1)

If you would like to go over the content about Read Only Domain Controllers you will also need:
- An RODC Server (RODC-P1)

``` terraform
RODC-P1 = {
  size       = "Standard_B2s"
  subnet_id  = azurerm_subnet.servers.id
  image_plan = "2022-datacenter-g2"
  data_disks = []
  private_ip = "10.0.1.10"
  public_ip  = null
  server_ou  = "OU=Servers,${local.domain_dn}"
}
```

## Lab Steps
1. From the Management Server, run the [ConfigureManagement.ps1](https://github.com/DanZab/az801/blob/main/Management/ConfigureManagement.ps1) script to install RSAT tools.

### Managing Password Settings
Password block lists are configured in Azure, this is a licensed feature that can't be covered in this lab so you will want to review the documentation: [Entra Password Protection](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-password-ban-bad)

1. Configure the default domain password policy via GPO
2. Create an AD Group and add some users. This group will be used to apply a more restrictive Password Policy to users within the group.
3. Create a Password Settings Object and apply it to the group you created. (HINT: You have to use the ADAC console)

### Protected Users
Read and understand the protections applied to the group: [Protected Users Security Group](https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/protected-users-security-group)

1. Enable Protected Users Log on Domain Controller (Microsoft/Windows/Authentication/ProtectedUser*)
2. Add a Domain Admin user to Protected Users group
3. Log out of DC/Log in with the user from Step 2
4. Review Log Entries from logs in step 1

### Built In Groups and Managing DC Access
[Built In Groups Reference Documentation](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/plan/security-best-practices/appendix-b--privileged-accounts-and-groups-in-active-directory#table-b-1-built-in-and-default-accounts-and-groups-in-active-directory)

1. On the management server, go to Computer Management and open Local Users and Groups > Groups
2. Expand the Description column and take a screenshot
3. Open Active Directory and go to the Built-In container
4. Compare Screenshot of local groups from step 1 to the groups within the AD Built-In Container
5. From the Management Server, try to RDP into the Domain Controller with a user who is not a Domain Admin
6. From the Built In Groups Reference Documentation linked above, look for a Built-In group that has the "Allow log on locally" permission. **Do not use the Administrators group**.
7. Add the user from step 5 to the group you identified in step 6.
8. Attempt to log into the Domain Controller again
9. Using the reference documentation for the group you used in step 7, what permissions does your user have on the Domain Controller?

### Managing AD Delegated Permissions
1. Identify two users that do not have any admin permissions currently. (Open the user in AD and look at "Member Of" tab, if it's empty the users do not have any permissions.)
2. Create a user in the Resources OU called "Service Account" or something similar. This will emulate a user being used as a service account.
3. Create two groups
  1. Name the first group to indicate it will be used for "Password Reset" permissions
  2. Name the second group to indicate it will be used for "Create and Manage Groups" permissions
4. Add the first user from Step 1 to the password reset group, add the second user from step 1 to the Create/Manage Groups group.
5. On the People OU in Active Directory, delegate permissions for password reset to the first group
6. On one of the **SUB** OUs under the Groups OU, delegate permissions to Create and Manage Groups. **Do not delegate them on the base "Groups" OU**.
7. From the management server, hold shift and right-click on Active Directory. Choose "Run As Different User" and launch AD as the first user from Step 1.
8. Attempt to reset the password of a user in the People OU, this should be successful.
9. Attempt to reset the password of the service account in the Resources OU you created in Step 2. This should fail due to lack of permissions.
10. Close the AD Console, then shift-right click again and run it as the second user from Step 1.
11. Attempt to create a new group in the Groups (base) OU, this should fail.
12. Attempt to create a new group or update the membership of a group within the OU you selected in Step 6. This should be successful.

### Authentication Policies and Silos
1. Identify your Domain Admin users. For this section you will use all of these users **EXCEPT** the default domain admin user you specified when you deployed the lab environment (so exclude the user listed in `main.tf` under the `admin_username` variable).
2. Modify the Default Domain Controllers Policy GPO and enable "KDC support for claims, compound authentication and Kerberos Armoring" and set it to "Always provide claims".
3. Modify the Default Domain Policy GPO and enable "Kerberos Client support for claims, compound authentication and Kerberos Armoring" and set it to "Always provide claims".
4. Run "GPUpdate /Force" on the Domain Controller
5. Run "GPUpdate /Force" on the Management Server
6. Restart both servers
7. Create an Authentication Policy that sets the TGT lifetime for Users to 120 minutes
8. Create an Authentication Policy Silo (make sure it's set to enforced).
  1. Add the users you identified in Step 1, and the Domain Controller computer object.
  2. Select the Authentication Policy you created in Step 7
9. Go back to the Authentication Policy you create in Step 7 and set the condition under "User Sign On" to only apply if the `User.AuthenticationSilo Equals (your Silo name from step 8)`.
9. Link the Authentication Policy Silo to each user and the domain controller you selected in Step 8-1 
10. Disconnect from your RDP session to the Management server and attempt to log in using one of the users from Step 1. This should be now be blocked due to the Auth Silo.

- Manage account security on an RODC
- Implement and manage Microsoft Defender for Identity