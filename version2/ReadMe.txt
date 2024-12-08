# Version 2 - Database Integration

## Περιγραφή
Αυτή η έκδοση περιλαμβάνει υλοποίηση που βασίζεται σε Java 17, Maven και PostgreSQL 9.4. Η εφαρμογή συνδέεται με βάση δεδομένων για την αποθήκευση και επεξεργασία δεδομένων λογαριασμών και συναλλαγών.

## Λειτουργίες API
1. Ανάκτηση στοιχείων δικαιούχου: GET /api/beneficiaries/{beneficiaryId}
2. Ανάκτηση λογαριασμών δικαιούχου: GET /api/beneficiaries/{beneficiaryId}/accounts
3. Ανάκτηση συναλλαγών δικαιούχου: GET /api/beneficiaries/{beneficiaryId}/accounts/transactions
4. Υπολογισμός υπολοίπου λογαριασμών: GET /api/beneficiaries/{beneficiaryId}/accounts/transactions/balance
5. Εύρεση μεγαλύτερης ανάληψης τον τελευταίο μήνα: GET /api/beneficiaries/{beneficiaryId}/accounts/transactions/maxWithdrawal

## Προαπαιτούμενα
- Java 17
- Maven
- PostgreSQL 9.4

## Οδηγίες Εγκατάστασης
1. Ρύθμιση Βάσης Δεδομένων
   - Δημιουργήστε μια νέα βάση δεδομένων σε PgAdmin3.
   - Τρέξτε το script creation_schema που βρίσκεται στον φάκελο db. Το script δημιουργεί ένα schema με ονομασία main, το οποίο περιέχει τους πίνακες beneficiaries, accounts και transactions μαζί με τα απαραίτητα indexes και sequences, καθώς και τις πέντε functions υλοποίησης.
   - Εισάγετε τα δεδομένα από τα αρχεία CSV που βρίσκονται στον ίδιο φάκελο.

2. Ρύθμιση Αρχείου application.properties
   - Ενημερώστε το αρχείο src/main/resources/application.properties με τα δικά σας credentials:
     spring.datasource.url=jdbc:postgresql://<HOST>:<PORT>/<DATABASE>
     spring.datasource.username=<USERNAME>
     spring.datasource.password=<PASSWORD>

3. Εκτέλεση της Εφαρμογής
  - Κατεβάστε το project:	git clone <repository_url>
     				            cd version2
  - Εκκινήστε την εφαρμογή:	mvn spring-boot:run
  - Δοκιμάστε τα endpoints στο: http://localhost:8080/api

## Σημειώσεις
- Το αρχείο application.properties έχει παραδοθεί με generic τιμές. Βεβαιωθείτε ότι το ενημερώσατε πριν εκτελέσετε την εφαρμογή.
