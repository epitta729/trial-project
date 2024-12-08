
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
    public Beneficiary getBen(@PathVariable int id){
        return beneficiaries.stream()
                .filter(b -> b.getBeneficiaryId() == id)
                .findFirst()
                .orElse(null);
    }
 
    //2. Retrieve beneficiary's accounts.
    @GetMapping("accounts/{beneficiaryId}")
    public List<Account> getBenAccounts(@PathVariable int beneficiaryId){
        return accounts.stream()
                .filter(a->a.getBeneficiaryId() == beneficiaryId)
                .collect(Collectors.toList());
    }
        
    //3. Retrieve beneficiary's transactions.
    @GetMapping("transactions/{beneficiaryId}")
    public List<Transaction> getBenTrans(@PathVariable int beneficiaryId){
        List<Account> benAcc = getBenAccounts(beneficiaryId);
        return transactions.stream()
                .filter(t-> benAcc.stream()
                            .anyMatch(b->b.getAccountId()== t.getAccountId()))
                .collect(Collectors.toList());
    }
    
    //4. Retrieve beneficiary's account balance.
    @GetMapping("balance/{beneficiaryId}")
    public List<AccountBalance> getBalance(@PathVariable int beneficiaryId) {
        return accounts.stream()
            .filter(a -> a.getBeneficiaryId() == beneficiaryId)
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
    }    
   
    //5. Retrieve the maximum withdrawal of a beneficiary for the last month.
    @GetMapping("maxWithdrawal/{beneficiaryId}")
    public Transaction getMaxWithdrawal(@PathVariable int beneficiaryId) {
        
        List<Account> benAcc = getBenAccounts(beneficiaryId);        
        //search all withdrawals of the person's accounts
        List<Transaction> withdrawals = transactions.stream()
            .filter(t -> benAcc.stream().anyMatch(a -> a.getAccountId() == t.getAccountId()))
            .filter(t -> t.getType().equalsIgnoreCase("withdrawal"))
            .collect(Collectors.toList());
        if (withdrawals.isEmpty()) {
            return null;
        }

        //get the last withdrawal date 
        Date latestTransDate = withdrawals.stream()
            .map(Transaction::getDate)
            .max(Date::compareTo)
            .orElse(null);
        if (latestTransDate == null) {
            return null;
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
            return null;
        }      
        //get the maximum withdrawal of the last month for that beneficiary
        return lastMonthWithdrawals.stream()
            .max(Comparator.comparingDouble(Transaction::getAmount))
            .orElse(null);                
    }

    
}
