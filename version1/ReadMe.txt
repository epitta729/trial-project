# Version 1 - Java-Only Implementation

## Περιγραφή
Αυτή είναι η Java-only υλοποίηση του project, η οποία περιλαμβάνει λειτουργίες διαχείρισης λογαριασμών και συναλλαγών για δικαιούχους. Το project αναπτύχθηκε με χρήση Java 17 και Maven στο περιβάλλον Apache Netbeans IDE 23. Όλα τα δεδομένα φορτώνονται από αρχεία CSV.

## Λειτουργίες AP
1. Ανάκτηση στοιχείων δικαιούχου: GET /api/beneficiaries/{beneficiaryId}
2. Ανάκτηση λογαριασμών δικαιούχου: GET /api/beneficiaries/{beneficiaryId}/accounts
3. Ανάκτηση συναλλαγών δικαιούχου: GET /api/beneficiaries/{beneficiaryId}/accounts/transactions
4. Υπολογισμός υπολοίπου λογαριασμών: GET /api/beneficiaries/{beneficiaryId}/accounts/transactions/balance
5. Εύρεση μεγαλύτερης ανάληψης τον τελευταίο μήνα: GET /api/beneficiaries/{beneficiaryId}/accounts/transactions/maxWithdrawal

## Προαπαιτούμενα
- Java 17
- Maven

## Εκτέλεση
1. Κατεβάστε το project: 	git clone <repository_url>
   				            cd version1
2. Εκκινήστε την εφαρμογή: 	mvn spring-boot:run
3. Δοκιμάστε τα endpoints στο: 	http://localhost:8080/api

## Δεδομένα
Τα δεδομένα (αρχεία CSV) βρίσκονται στον φάκελο:

src/main/resources/
├── beneficiaries.csv
├── accounts.csv
├── transactions.csv
