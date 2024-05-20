# Secure Windows Server operating system
Back to [Guided Labs](https://github.com/DanZab/az801/tree/main/Guided%20Labs) index.

**Exam Objectives**
- Configure and manage Exploit Protection
- Configure and manage Windows Defender Application Control
- Configure and manage Microsoft Defender for Endpoint
- Configure and manage Windows Defender Credential Guard
- Configure SmartScreen
- Implement operating system security by using Group Policies

**Videos**


- [Describe Windows Defender Credential Guard - Training | Microsoft Learn](https://learn.microsoft.com/en-us/training/modules/secure-windows-server-user-accounts/4-what-is-windows-defender-credential-guard)

## Lab Setup
Use Default Lab Deployment
- Domain Controller
- Management Server

## Lab Steps
### Exploit Protection
[Exploit protection reference | Microsoft Learn](https://learn.microsoft.com/en-us/microsoft-365/security/defender-endpoint/exploit-protection-reference?view=o365-worldwide)

Logging mitigations requires a Defender for Endpoint license. That is not covered in the lab. Advanced reporting and events can be seen in the Defender portal if a license is used.

1. Configure some Exploit Protection Settings (Windows Settings)
2. Export the settings you configured
3. Deploy those settings via a GPO

### Windows Defender Application Control
[Windows Defender Application Control (WDAC) Deployment Guide](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/wdac-deployment-guide)
[Windows Defender Application Control Wizard - Windows Security | Microsoft Learn](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/design/wdac-wizard)

WDAC settings can be deployed via Intune, SCCM or Powershell. There are some very limited GPO-based options as well.

