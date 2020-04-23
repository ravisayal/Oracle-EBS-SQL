/*************************************************************************/
/*                                                                       */
/*                       (c) 2010-2020 Enginatics GmbH                   */
/*                              www.enginatics.com                       */
/*                                                                       */
/*************************************************************************/
-- Report Name: AR Transactions and Payments
-- Description: Customer Balance. Receivables billing history including customer payments.
Note: As this report is based on table ar_payment_schedules_all, it doesn't show entered, incomplete transactions.
-- Excel Examle Output: https://www.enginatics.com/example/ar-transactions-and-payments/
-- Library Link: https://www.enginatics.com/reports/ar-transactions-and-payments/
-- Run Report: https://demo.enginatics.com/

select
x.ou,
x.invoice_number,
x.trx_number,
x.trx_date,
x.class,
x.type,
x.reference,
x.credited_invoice,
x.account_number,
x.party_name,
x.currency,
x.due_original,
x.payment_applied,
x.adjustment,
x.credit,
x.due_remaining,
x.dispute_amount,
x.state,
x.status,
x.payment_term,
x.invoicing_rule,
x.due_date,
x.overdue_days,
x.ship_date,
arm.name receipt_method,
ifpct.payment_channel_name payment_method,
decode(ipiua.instrument_type,'BANKACCOUNT',ieba.masked_bank_account_num,'CREDITCARD',ic.masked_cc_number) instrument_number,
nvl(ifte.payment_system_order_number,nvl2(ifte.trxn_extension_id,substr(iby_fndcpt_trxn_pub.get_tangible_id(fa.application_short_name,ifte.order_id,ifte.trxn_ref_number1,ifte.trxn_ref_number2),1,80),null)) pson,
hp2.party_name bank_name,
hp3.party_name bank_branch,
x.remit_bank_name,
x.remit_bank_branch,
x.remit_bank_account,
x.print_option,
x.first_printed_date,
x.customer_reference,
x.comments,
x.bill_to_location,
x.bill_to_address,
x.taxpayer_id,
x.sales_rep,
x.category,
xxen_util.user_name(x.created_by) created_by,
xxen_util.client_time(x.creation_date) creation_date,
xxen_util.user_name(x.last_updated_by) last_updated_by,
xxen_util.client_time(x.last_update_date) last_update_date
from
(
select
haou.name ou,
acia.cons_billing_number invoice_number,
nvl(rcta.trx_number,acra.receipt_number) trx_number,
apsa.trx_date,
flv1.meaning class,
nvl(rctta.name,'Standard') type,
nvl(rcta.ct_reference,acra.customer_receipt_reference) reference,
decode(apsa.class,'PMT',
(
select distinct
listagg(nvl2(acia0.cons_billing_number,acia0.cons_billing_number||' - ',null)||rcta0.trx_number,', ') within group (order by rcta0.trx_number) over (partition by araa.cash_receipt_id) applied_trx
from
ar_receivable_applications_all araa,
ra_customer_trx_all rcta0,
ar_cons_inv_trx_all acita0,
ar_cons_inv_all acia0
where
apsa.cash_receipt_id=araa.cash_receipt_id and
araa.display='Y' and
araa.status='APP' and
araa.applied_customer_trx_id=rcta0.customer_trx_id and
rcta0.customer_trx_id=acita0.customer_trx_id(+) and
acita0.cons_inv_id=acia0.cons_inv_id(+)
),
(
select
nvl2(acia0.cons_billing_number,acia0.cons_billing_number||' - ',null)||rcta0.trx_number credited_invoice
from
ra_customer_trx_all rcta0,
ar_cons_inv_trx_all acita0,
ar_cons_inv_all acia0
where
rcta.previous_customer_trx_id=rcta0.customer_trx_id and
rcta0.customer_trx_id=acita0.customer_trx_id(+) and
acita0.cons_inv_id=acia0.cons_inv_id(+)
)
) credited_invoice,
hca.account_number,
hp.party_name,
hcsua.location bill_to_location,
hz_format_pub.format_address (hps.location_id,null,null,' , ') bill_to_address,
hp.jgzz_fiscal_code taxpayer_id,
apsa.invoice_currency_code currency,
apsa.amount_due_original due_original,
apsa.amount_applied payment_applied,
apsa.amount_adjusted adjustment,
apsa.amount_credited credit,
apsa.amount_due_remaining due_remaining,
case when rctta.accounting_affect_flag='Y' and apsa.amount_in_dispute<>0 then apsa.amount_in_dispute end dispute_amount,
nvl(flv3.meaning,decode(apsa.status,'CL','Closed',decode(apsa.amount_due_remaining,apsa.amount_due_original,'Open','Partially Paid'))) state,
apsa.status,
rtt.name payment_term,
decode(rcta.invoicing_rule_id,-3,'Arrears',-2,'Advance') invoicing_rule,
apsa.due_date,
case when apsa.class in ('INV','DM') and apsa.status='OP' then greatest(trunc(sysdate)-apsa.due_date,0) end overdue_days,
rcta.ship_date_actual ship_date,
hop.organization_name remit_bank_name,
hp4.party_name remit_bank_branch,
case when cba.bank_account_id is not null then ce_bank_and_account_util.get_masked_bank_acct_num(cba.bank_account_id) end remit_bank_account,
flv2.meaning print_option,
rcta.printing_original_date first_printed_date,
rcta.customer_reference,
nvl(rcta.comments,acra.comments) comments,
jrret.resource_name sales_rep,
decode(apsa.class,'PMT','CASH RECEIPT',nvl(rcta.interface_header_context,rbsa.name)) category,
nvl(rcta.created_by,acra.created_by) created_by,
nvl(rcta.creation_date,acra.creation_date) creation_date,
nvl(rcta.last_updated_by,acra.last_updated_by) last_updated_by,
nvl(rcta.last_update_date,acra.last_update_date) last_update_date,
nvl(rcta.receipt_method_id,acra.receipt_method_id) receipt_method_id,
nvl(rcta.payment_trxn_extension_id,acra.payment_trxn_extension_id) payment_trxn_extension_id
from
hr_all_organization_units haou,
ar_payment_schedules_all apsa,
ra_customer_trx_all rcta,
oe_sys_parameters_all ospa,
ra_batch_sources_all rbsa,
ra_cust_trx_types_all rctta,
ra_terms_tl rtt,
ar_cons_inv_all acia,
hz_cust_accounts hca,
hz_parties hp,
hz_cust_site_uses_all hcsua,
hz_cust_acct_sites_all hcasa,
hz_party_sites hps,
fnd_lookup_values flv1,
fnd_lookup_values flv2,
jtf_rs_salesreps jrs,
jtf_rs_resource_extns_tl jrret,
ar_cash_receipts_all acra,
ar_cash_receipt_history_all acrha,
fnd_lookup_values flv3,
ce_bank_acct_uses_all cbaua,
ce_bank_accounts cba,
hz_parties hp4,
hz_relationships hr,
(select hop.* from hz_organization_profiles hop where sysdate between hop.effective_start_date and nvl(hop.effective_end_date,sysdate)) hop
where
1=1 and
apsa.payment_schedule_id>0 and
apsa.org_id=haou.organization_id and
apsa.customer_trx_id=rcta.customer_trx_id(+) and
apsa.org_id=ospa.org_id(+) and
ospa.parameter_code(+)='MASTER_ORGANIZATION_ID' and
apsa.term_id=rtt.term_id(+) and
rtt.language(+)=userenv('LANG') and
rcta.cust_trx_type_id=rctta.cust_trx_type_id(+) and
rcta.org_id=rctta.org_id(+) and
nvl2(rcta.interface_header_context,null,rcta.batch_source_id)=rbsa.batch_source_id(+) and
nvl2(rcta.interface_header_context,null,rcta.org_id)=rbsa.org_id(+) and
apsa.cons_inv_id=acia.cons_inv_id(+) and
apsa.customer_id=hca.cust_account_id(+) and
hca.party_id=hp.party_id(+) and
apsa.customer_site_use_id=hcsua.site_use_id(+) and
hcsua.cust_acct_site_id=hcasa.cust_acct_site_id(+) and
hcasa.party_site_id=hps.party_site_id(+) and
apsa.class=flv1.lookup_code(+) and
rcta.printing_option=flv2.lookup_code(+) and
flv1.lookup_type(+)='INV/CM/ADJ' and
flv2.lookup_type(+)='INVOICE_PRINT_OPTIONS' and
flv1.view_application_id(+)=222 and
flv2.view_application_id(+)=222 and
flv1.language(+)=userenv('lang') and
flv2.language(+)=userenv('lang') and
flv1.security_group_id(+)=0 and
flv2.security_group_id(+)=0 and
case when rcta.primary_salesrep_id>0 then rcta.primary_salesrep_id end=jrs.salesrep_id(+) and
case when rcta.primary_salesrep_id>0 then rcta.org_id end=jrs.org_id(+) and
jrs.resource_id=jrret.resource_id(+) and
jrret.language(+)=userenv('lang') and
apsa.cash_receipt_id=acra.cash_receipt_id(+) and
apsa.cash_receipt_id=acrha.cash_receipt_id(+) and
acrha.current_record_flag(+)='Y' and
acrha.status=flv3.lookup_code(+) and
flv3.lookup_type(+)='RECEIPT_CREATION_STATUS' and
flv3.view_application_id(+)=222 and
flv3.language(+)=userenv('lang') and
flv3.security_group_id(+)=0 and
acra.remit_bank_acct_use_id=cbaua.bank_acct_use_id(+) and
cbaua.bank_account_id=cba.bank_account_id(+) and
cba.bank_branch_id=hp4.party_id(+) and
hp4.party_id=hr.subject_id(+) and
hr.relationship_type(+)='BANK_AND_BRANCH' and
hr.relationship_code(+)='BRANCH_OF' and
hr.status(+)='A' and
hr.subject_table_name(+)='HZ_PARTIES' and
hr.subject_type(+)='ORGANIZATION' and
hr.object_table_name(+)='HZ_PARTIES' and
hr.object_type(+)='ORGANIZATION' and
hr.object_id=hop.party_id(+)
) x,
ar_receipt_methods arm,
iby_fndcpt_pmt_chnnls_tl ifpct,
iby_fndcpt_tx_extensions ifte,
fnd_application fa,
iby_pmt_instr_uses_all ipiua,
iby_ext_bank_accounts ieba,
hz_parties hp2,
hz_parties hp3,
iby_creditcard ic
where
x.receipt_method_id=arm.receipt_method_id(+) and
arm.payment_channel_code=ifpct.payment_channel_code(+) and
ifpct.language(+)=userenv('lang') and
x.payment_trxn_extension_id=ifte.trxn_extension_id(+) and
ifte.origin_application_id=fa.application_id(+) and
ifte.instr_assignment_id=ipiua.instrument_payment_use_id(+) and
decode(ipiua.instrument_type,'BANKACCOUNT',ipiua.instrument_id)=ieba.ext_bank_account_id(+) and
ieba.bank_id=hp2.party_id(+) and
ieba.branch_id=hp3.party_id(+) and
decode(ipiua.instrument_type,'CREDITCARD',ipiua.instrument_id)=ic.instrid(+)
order by
x.ou,
x.trx_date desc,
x.invoice_number desc,
x.trx_number desc