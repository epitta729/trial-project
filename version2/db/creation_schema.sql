--
-- PostgreSQL database dump
--

-- Dumped from database version 9.4.26
-- Dumped by pg_dump version 9.4.26
-- Started on 2024-12-07 20:45:43

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;

--
-- TOC entry 8 (class 2615 OID 16394)
-- Name: main; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA main;


ALTER SCHEMA main OWNER TO postgres;

--
-- TOC entry 198 (class 1255 OID 16490)
-- Name: get_max_withdrawal_last_month(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.get_max_withdrawal_last_month(beneficiary_id bigint) RETURNS TABLE(transactionid bigint, accountid bigint, amount numeric, transaction_date date)
    LANGUAGE plpgsql
    AS $$
DECLARE
    last_trans_date DATE;
    first_day_of_month DATE;
    last_day_of_month DATE;
BEGIN

	
    -- latest transaction of the beneficiary
    select MAX(t.trans_date)
    into last_trans_date
    from main.transactions t,main.accounts a 
    where t.accountid = a.accountid and a.beneficiaryid = beneficiary_id;

    if last_trans_date is null then
        return; -- No transactions
    end if;

    -- first and last day of latest months' transaction
    first_day_of_month := date_trunc('month', last_trans_date);
    last_day_of_month := (first_day_of_month + interval '1 month' - interval '1 day')::DATE;

    -- Find the max withdrawal of that month for the requested beneficiary
    RETURN QUERY
    select t.transactionid, t.accountid, t.amount, t.trans_date
    from main.transactions t, main.accounts a 
    WHERE t.accountid = a.accountid 
	and a.beneficiaryid = beneficiary_id
	and t.type = 'withdrawal'
	and t.trans_date between first_day_of_month and last_day_of_month
    order by t.amount desc
    limit 1;
END;
$$;


ALTER FUNCTION main.get_max_withdrawal_last_month(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 199 (class 1255 OID 16492)
-- Name: getbalance(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getbalance(beneficiary_id bigint) RETURNS TABLE(accountid bigint, balance numeric)
    LANGUAGE plpgsql
    AS $$
  
BEGIN
	RETURN QUERY
	select 	t.accountid
		,SUM(case WHEN t.type = 'deposit' THEN t.amount 
			WHEN t.type = 'withdrawal' THEN -t.amount 
                ELSE 0 END) AS balance
	from main.transactions t,main.accounts a 
	where t.accountid = a.accountid and a.beneficiaryid = beneficiary_id
	group by t.accountid;


END;
$$;


ALTER FUNCTION main.getbalance(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 196 (class 1255 OID 16485)
-- Name: getben_accounts(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getben_accounts(beneficiary_id bigint) RETURNS TABLE(accountid bigint)
    LANGUAGE plpgsql
    AS $$
   
BEGIN
	RETURN QUERY
	select a.accountid
	from main.accounts a
	where a.beneficiaryid=beneficiary_id;

END;
$$;


ALTER FUNCTION main.getben_accounts(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 197 (class 1255 OID 16487)
-- Name: getben_transactions(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getben_transactions(beneficiary_id bigint) RETURNS TABLE(accountid bigint, amount numeric, type character varying, trans_date date)
    LANGUAGE plpgsql
    AS $$
   
BEGIN
	RETURN QUERY
	select a.accountid,t.amount,t.type,t.trans_date
	from main.transactions t,main.accounts a
	where t.accountid=a.accountid 
		and a.beneficiaryid=beneficiary_id;

END;
$$;


ALTER FUNCTION main.getben_transactions(beneficiary_id bigint) OWNER TO postgres;

--
-- TOC entry 195 (class 1255 OID 16484)
-- Name: getbeninfo(bigint); Type: FUNCTION; Schema: main; Owner: postgres
--

CREATE FUNCTION main.getbeninfo(beneficiary_id bigint) RETURNS TABLE(firstname character varying, lastname character varying)
    LANGUAGE plpgsql
    AS $$
   
BEGIN
	RETURN QUERY
	select b.firstname,b.lastname 
	from main.beneficiaries b
	where b.beneficiaryid=beneficiary_id;

END;
$$;


ALTER FUNCTION main.getbeninfo(beneficiary_id bigint) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 177 (class 1259 OID 16439)
-- Name: accounts; Type: TABLE; Schema: main; Owner: postgres; Tablespace: 
--

CREATE TABLE main.accounts (
    accountid bigint NOT NULL,
    beneficiaryid bigint NOT NULL
);


ALTER TABLE main.accounts OWNER TO postgres;

--
-- TOC entry 176 (class 1259 OID 16437)
-- Name: accounts_accountid_seq; Type: SEQUENCE; Schema: main; Owner: postgres
--

CREATE SEQUENCE main.accounts_accountid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.accounts_accountid_seq OWNER TO postgres;

--
-- TOC entry 2045 (class 0 OID 0)
-- Dependencies: 176
-- Name: accounts_accountid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: postgres
--

ALTER SEQUENCE main.accounts_accountid_seq OWNED BY main.accounts.accountid;


--
-- TOC entry 175 (class 1259 OID 16431)
-- Name: beneficiaries; Type: TABLE; Schema: main; Owner: postgres; Tablespace: 
--

CREATE TABLE main.beneficiaries (
    beneficiaryid bigint NOT NULL,
    firstname character varying(50),
    lastname character varying(50)
);


ALTER TABLE main.beneficiaries OWNER TO postgres;

--
-- TOC entry 174 (class 1259 OID 16429)
-- Name: beneficiaries_beneficiaryid_seq; Type: SEQUENCE; Schema: main; Owner: postgres
--

CREATE SEQUENCE main.beneficiaries_beneficiaryid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.beneficiaries_beneficiaryid_seq OWNER TO postgres;

--
-- TOC entry 2046 (class 0 OID 0)
-- Dependencies: 174
-- Name: beneficiaries_beneficiaryid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: postgres
--

ALTER SEQUENCE main.beneficiaries_beneficiaryid_seq OWNED BY main.beneficiaries.beneficiaryid;


--
-- TOC entry 179 (class 1259 OID 16453)
-- Name: transactions; Type: TABLE; Schema: main; Owner: postgres; Tablespace: 
--

CREATE TABLE main.transactions (
    transactionid bigint NOT NULL,
    accountid bigint NOT NULL,
    amount numeric(10,2) NOT NULL,
    type character varying(20) NOT NULL,
    trans_date date NOT NULL,
    CONSTRAINT transactions_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT transactions_type_check CHECK (((type)::text = ANY (ARRAY[('withdrawal'::character varying)::text, ('deposit'::character varying)::text])))
);


ALTER TABLE main.transactions OWNER TO postgres;

--
-- TOC entry 178 (class 1259 OID 16451)
-- Name: transactions_transactionid_seq; Type: SEQUENCE; Schema: main; Owner: postgres
--

CREATE SEQUENCE main.transactions_transactionid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.transactions_transactionid_seq OWNER TO postgres;

--
-- TOC entry 2047 (class 0 OID 0)
-- Dependencies: 178
-- Name: transactions_transactionid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: postgres
--

ALTER SEQUENCE main.transactions_transactionid_seq OWNED BY main.transactions.transactionid;


--
-- TOC entry 1911 (class 2604 OID 16442)
-- Name: accountid; Type: DEFAULT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.accounts ALTER COLUMN accountid SET DEFAULT nextval('main.accounts_accountid_seq'::regclass);


--
-- TOC entry 1910 (class 2604 OID 16434)
-- Name: beneficiaryid; Type: DEFAULT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.beneficiaries ALTER COLUMN beneficiaryid SET DEFAULT nextval('main.beneficiaries_beneficiaryid_seq'::regclass);


--
-- TOC entry 1912 (class 2604 OID 16456)
-- Name: transactionid; Type: DEFAULT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.transactions ALTER COLUMN transactionid SET DEFAULT nextval('main.transactions_transactionid_seq'::regclass);

SELECT pg_catalog.setval('main.transactions_transactionid_seq', 1, false);


--
-- TOC entry 1918 (class 2606 OID 16444)
-- Name: accounts_pkey; Type: CONSTRAINT; Schema: main; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY main.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (accountid);


--
-- TOC entry 1916 (class 2606 OID 16436)
-- Name: beneficiaries_pkey; Type: CONSTRAINT; Schema: main; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY main.beneficiaries
    ADD CONSTRAINT beneficiaries_pkey PRIMARY KEY (beneficiaryid);


--
-- TOC entry 1922 (class 2606 OID 16460)
-- Name: transactions_pkey; Type: CONSTRAINT; Schema: main; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY main.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transactionid);


--
-- TOC entry 1919 (class 1259 OID 16450)
-- Name: idx_accounts_beneficiaryid; Type: INDEX; Schema: main; Owner: postgres; Tablespace: 
--

CREATE INDEX idx_accounts_beneficiaryid ON main.accounts USING btree (beneficiaryid);


--
-- TOC entry 1920 (class 1259 OID 16466)
-- Name: idx_transactions_accountid; Type: INDEX; Schema: main; Owner: postgres; Tablespace: 
--

CREATE INDEX idx_transactions_accountid ON main.transactions USING btree (accountid);


--
-- TOC entry 1923 (class 2606 OID 16445)
-- Name: accben_fkey; Type: FK CONSTRAINT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.accounts
    ADD CONSTRAINT accben_fkey FOREIGN KEY (beneficiaryid) REFERENCES main.beneficiaries(beneficiaryid) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 1924 (class 2606 OID 16461)
-- Name: transacc_fkey; Type: FK CONSTRAINT; Schema: main; Owner: postgres
--

ALTER TABLE ONLY main.transactions
    ADD CONSTRAINT transacc_fkey FOREIGN KEY (accountid) REFERENCES main.accounts(accountid) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2024-12-07 20:45:43

--
-- PostgreSQL database dump complete
--

