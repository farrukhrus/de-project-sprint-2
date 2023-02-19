insert into shipping_country_rates ( shipping_country, shipping_country_base_rate) 
(select distinct shipping_country, shipping_country_base_rate from shipping);

insert into shipping_agreement (agreementid,agreement_number,agreement_rate,agreement_commission)
(select distinct arr[1]::bigint as agreementid, 
		arr[2] as agreement_number, 
		arr[3]::numeric(14,2) as agreement_rate, 
		arr[4]::numeric(14,2) as agreement_commission
 from (
		select (regexp_split_to_array(vendor_agreement_description , E'\\:+')) as arr 
		from shipping s) as t
);

insert into shipping_transfer (transfer_type, transfer_model, shipping_transfer_rate)
( select 
	distinct arr[1] as transfer_type,
	arr[2] as transfer_model,
	shipping_transfer_rate
  from ( 
  	select regexp_split_to_array(shipping_transfer_description ,E'\\:+') as arr, shipping_transfer_rate
  	from shipping
  ) t
);

insert into shipping_info ( 
	vendorid, payment_amount, shipping_plan_datetime, 
	transfer_type_id, shipping_country_id, agreement_id)
select  sh.vendorid,
		sh.payment_amount,
		sh.shipping_plan_datetime,
		st.id as transfer_type_id,
		scr.id as shipping_country_id,
		sa.agreementid as agreement_id
from shipping  sh
inner join shipping_transfer st on sh.shipping_transfer_description = concat(st.transfer_type,':',st.transfer_model)
inner join shipping_country_rates scr 
	on (sh.shipping_country=scr.shipping_country and sh.shipping_country_base_rate = scr.shipping_country_base_rate)
inner join shipping_agreement sa 
	on sh.vendor_agreement_description = 
	   concat(sa.agreementid,':',sa.agreement_number,':',sa.agreement_rate,':',agreement_commission);
	   
insert into shipping_status ( shippingid, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime )
(
with t as (
	select 	shippingid, 
			max(case when state='booked' then state_datetime else null end) as shipping_start_fact_datetime,
		   	max(case when state='recieved' then state_datetime else null end) as shipping_end_fact_datetime,
		   	max(state_datetime) as state_datetime
    from shipping 
    --where state not in ('pending')
    group by 1
)
select 
	s.shippingid,
	s.status,
	s.state,
	t.shipping_start_fact_datetime,
	t.shipping_end_fact_datetime
from shipping s inner join t on (s.shippingid =t.shippingid and s.state_datetime=t.state_datetime) );

insert into shipping_datamart (
	shippingid, vendorid, transfer_type, full_day_at_shipping, is_delay, 
	is_shipping_finish, delay_day_at_shipping, payment_amount, vat, profit
)
select
	si.shippingid,
	si.vendorid,
	st.transfer_type,
	date_part('day', (shipping_end_fact_datetime-shipping_start_fact_datetime)) as full_day_at_shipping,
	case when shipping_end_fact_datetime>shipping_start_fact_datetime then 1 else 0 end as is_delay,
	case when status='finished' then 1 else 0 end as is_shipping_finish,
	case 
		when shipping_end_fact_datetime>shipping_plan_datetime 
			then date_part('day', ss.shipping_end_fact_datetime-si.shipping_plan_datetime)
		else 0
	end as delay_day_at_shipping,
	si.payment_amount,
	payment_amount*(scr.shipping_country_base_rate+agreement_rate+st.shipping_transfer_rate) as vat,
	payment_amount*sa.agreement_commission as profit
from shipping_info si 
	 inner join shipping_status ss on si.shippingid = ss.shippingid
	 inner join shipping_transfer st on si.transfer_type_id =st.id 
	 inner join shipping_country_rates scr on si.shipping_country_id = scr.id 
	 inner join shipping_agreement sa on si.agreement_id = sa.agreementid 