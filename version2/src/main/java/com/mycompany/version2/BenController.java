
package com.mycompany.version2;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 *
 * @author eleni
 */
@RestController
@RequestMapping("/api")
public class BenController {
    
    @Autowired
    private BenService benservice;
    
    // 1. Retrieve beneficiary information.
    @GetMapping("/beneficiaries/{id}")
    public ResponseEntity<?> getBenInfos(@PathVariable Long id) {
        try {
            Object result = benservice.getBenInfo(id);
            if (result == null || ((List<?>) result).isEmpty()) {
                return ResponseEntity.notFound().build(); // 404 Not Found
            }
            return ResponseEntity.ok(result); // 200 OK
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving beneficiary information"); // 500 Internal Server Error
        }
    }
    
    //2. Retrieve beneficiary's accounts.
    @GetMapping("/beneficiaries/{id}/accounts")
    public ResponseEntity<?> getBenAccounts(@PathVariable Long id) {
        try {
            Object result =  benservice.getBenAccounts(id);
            if (result == null || ((List<?>) result).isEmpty()) {
                return ResponseEntity.notFound().build(); // 404 Not Found
            }
            return ResponseEntity.ok(result); // 200 OK
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving accounts"); // 500 Internal Server Error
        }
    }
    
    //3. Retrieve beneficiary's transactions
    @GetMapping("/beneficiaries/{id}/accounts/transactions")
    public ResponseEntity<?> getBenTransactions(@PathVariable Long id){
        try {
            Object result = benservice.getBenTransactions(id);
            if (result == null || ((List<?>) result).isEmpty()) {
                return ResponseEntity.notFound().build(); // 404 Not Found
            }
            return ResponseEntity.ok(result); // 200 OK
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving transactions"); // 500 Internal Server Error
        }
    }
    
    //4. Retrieve beneficiary's account balance
    @GetMapping("/beneficiaries/{id}/accounts/transactions/balance")
    public ResponseEntity<?> getBalance(@PathVariable Long id){
        try {
            Object result = benservice.getBalance(id); 
            if (result == null || ((List<?>) result).isEmpty()) {
                return ResponseEntity.notFound().build(); // 404 Not Found
            }
            return ResponseEntity.ok(result); // 200 OK
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving balance"); // 500 Internal Server Error
        }
    }
    
    //5. Retrieve the maximum withdrawal of a beneficiary for the last month
    @GetMapping("/beneficiaries/{id}/accounts/transactions/maxWithdrawal")
    public ResponseEntity<?> getMaxWithdrawal(@PathVariable Long id){
        try {
            Object result = benservice.getMaxWithdrawal(id);
            if (result == null || ((List<?>) result).isEmpty()) {
                return ResponseEntity.notFound().build(); // 404 Not Found
            }
            return ResponseEntity.ok(result); // 200 OK
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error retrieving maximum withdrawal of a beneficiary for the last month"); // 500 Internal Server Error
        }
    }
            
}
