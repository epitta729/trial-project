
package com.mycompany.version1;

import com.opencsv.exceptions.CsvValidationException;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.text.ParseException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 *
 * @author eleni
 */
@RestController
@RequestMapping("/api")
public class AccountController {
    
    private final List<Beneficiary> beneficiaries;
    private final List<Account> accounts;
    private final List<Transaction> transactions;
    
    public AccountController() throws IOException, FileNotFoundException, CsvValidationException, ParseException {
        this.beneficiaries = ReadCsv.readBeneficiaries("beneficiaries.csv");
        this.accounts = ReadCsv.readAccounts("accounts.csv");
        this.transactions = ReadCsv.readTransactions("transactions.csv");
    }
    
    //1. Retrieve beneficiary details.
    @GetMapping("/beneficiaries/{id}")
    public ResponseEntity<?> getBen(@PathVariable int id){
        try {
            Beneficiary beneficiary = beneficiaries.stream()
                .filter(b -> b.getBeneficiaryId() == id)
                .findFirst()
                .orElse(null);
            if (beneficiary == null) {
                return ResponseEntity.notFound().build();// 404 Not Found
            }
            
            return ResponseEntity.ok(beneficiary); //200 Ok
        } catch (Exception e){
            return ResponseEntity.internalServerError().body("Error retrieving beneficiary details"); //500 Internal Server Error
        }
    }
 
    //2. Retrieve beneficiary's accounts.
    @GetMapping("/beneficiaries/{id}/accounts")
    public ResponseEntity<?> getBenAccounts(@PathVariable int id){
        try {
            List<Account> accountList = accounts.stream()
                .filter(a->a.getBeneficiaryId() == id)
                .collect(Collectors.toList());
            
            if (accountList.isEmpty()){
                return ResponseEntity.notFound().build();// 404 Not Found
            }
            return ResponseEntity.ok(accountList); //200 Ok
        } catch (Exception e){
            return ResponseEntity.internalServerError().body("Error retrieving beneficiary accounts"); //500 Internal Server Error
        }
            
    }
        
    //3. Retrieve beneficiary's transactions.
    @GetMapping("/beneficiaries/{id}/accounts/transactions")
    public ResponseEntity<?> getBenTrans(@PathVariable int id){
        try{
            List<Account> benAcc = accounts.stream()
                    .filter(a-> a.getBeneficiaryId() ==id)
                    .collect(Collectors.toList());
            
            if(benAcc.isEmpty()){
                return ResponseEntity.notFound().build();// 404 Not Found
            }
            List<Transaction> transactionsList = transactions.stream()
                .filter(t-> benAcc.stream()
                            .anyMatch(b->b.getAccountId()== t.getAccountId()))
                .collect(Collectors.toList());
            
            if(transactionsList.isEmpty()){
                return ResponseEntity.notFound().build();// 404 Not Found
            }
            return ResponseEntity.ok(transactionsList); // 200 Ok    
        } catch (Exception e){
            return ResponseEntity.internalServerError().body("Error retrieving beneficiary transactions"); //500 Internal Server Error
        }
    }
    
    //4. Retrieve beneficiary's account balance.
    @GetMapping("/beneficiaries/{id}/accounts/transactions/balance")
    public ResponseEntity<?> getBalance(@PathVariable int id) {
        
        try {
            List<AccountBalance> balances = accounts.stream()
                .filter(a -> a.getBeneficiaryId() == id)
                .map(a -> {
                        double balance = transactions.stream()
                            .filter(t -> t.getAccountId() == a.getAccountId())
                            .mapToDouble(t -> {
                                if (t.getType().equalsIgnoreCase("deposit")){
                                    return t.getAmount();
                                }else if(t.getType().equalsIgnoreCase("withdrawal")){
                                    return -t.getAmount();
                                }else{
                                    return 0;
                                }                    
                            })
                            .sum();                                      
                        return new AccountBalance(a.getAccountId(),balance);
                })
                .collect(Collectors.toList()); 
            if(balances.isEmpty()){
                return ResponseEntity.notFound().build();// 404 Not Found
            }
            return ResponseEntity.ok(balances); // 200 Ok
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving account balance"); // 500 Internal Server Error
        }
    }    
   
    //5. Retrieve the maximum withdrawal of a beneficiary for the last month.
    @GetMapping("/beneficiaries/{id}/accounts/transactions/maxWithdrawal")
    public ResponseEntity<?> getMaxWithdrawal(@PathVariable int id) {
        try{
            List<Account> benAcc = accounts.stream()
                    .filter(a-> a.getBeneficiaryId() == id)
                    .collect(Collectors.toList());
            if(benAcc.isEmpty()){
                return ResponseEntity.notFound().build();
            }
            
            //search all withdrawals of the person's accounts
            List<Transaction> withdrawals = transactions.stream()
                .filter(t -> benAcc.stream().anyMatch(a -> a.getAccountId() == t.getAccountId()))
                .filter(t -> t.getType().equalsIgnoreCase("withdrawal"))
                .collect(Collectors.toList());
            if (withdrawals.isEmpty()) {
                return ResponseEntity.notFound().build();// 404 Not Found
            }

            //get the last withdrawal date 
            Date latestTransDate = withdrawals.stream()
                .map(Transaction::getDate)
                .max(Date::compareTo)
                .orElse(null);
            if (latestTransDate == null) {
                return ResponseEntity.notFound().build();// 404 Not Found
            }
            //Local date
            LocalDate latestTransLocalDate = latestTransDate.toInstant()
                    .atZone(ZoneId.systemDefault())
                    .toLocalDate();
            //search all withdrawals of every account of the beneficiary 
            List<Transaction> lastMonthWithdrawals = withdrawals.stream()
                .filter(t -> {
                    LocalDate transactionDate = t.getDate().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
                    return transactionDate.getMonth()==latestTransLocalDate.getMonth() && transactionDate.getYear()==latestTransLocalDate.getYear();
                })
                    .collect(Collectors.toList());
            if(lastMonthWithdrawals.isEmpty()){
                return ResponseEntity.notFound().build();// 404 Not Found
            }      
            //get the maximum withdrawal of the last month for that beneficiary
            Transaction maxwithdrawal = lastMonthWithdrawals.stream()
                .max(Comparator.comparingDouble(Transaction::getAmount))
                .orElse(null); 
            if(maxwithdrawal == null){
                return ResponseEntity.notFound().build();// 404 Not Found
            } 
            
            return ResponseEntity.ok(maxwithdrawal); // 200 Ok
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving maximum withdrawal"); // 500 Internal Server Error
        }
    }

    
}
