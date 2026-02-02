# Windows-UEFI-CA-2023
Secure Boot CA 2023 är ett nytt Microsoft‑certifikat som används av UEFI Secure Boot för att verifiera att Windows startar med äkta och betrodd programvara. Det ersätter de gamla certifikaten från 2011 och behövs för framtida Windows‑uppdateringar och bootloaders.

Detect
Skriptet kontrollerar om Secure Boot är på, om CA 2023‑certifikatet finns, läser servicing‑status, letar efter event 1808, och avgör om systemet är compliant eller inte.
Remediation
Skriptet tvingar fram installationen av Secure Boot CA 2023 genom att sätta rätt registry‑värde och starta Windows inbyggda uppdaterings‑task om systemet inte redan är uppdaterat.
