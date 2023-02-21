drop table if exists shipping_country_rates cascade;
create table shipping_country_rates 
(
	id serial primary key,
	shipping_country text,
	shipping_country_base_rate numeric(14, 3)
);

drop table if exists shipping_agreement  cascade;
create table shipping_agreement (
	agreementid bigint primary key,
	agreement_number text,
	agreement_rate numeric(14,2),
	agreement_commission numeric(14,2)
);

drop table if exists shipping_transfer  cascade;
create table shipping_transfer (
	id serial primary key,
	transfer_type text,
	transfer_model text,
	shipping_transfer_rate numeric(14, 3)
);

drop table if exists shipping_info  cascade;
create table shipping_info (
	shippingid serial primary key,
	vendorid bigint,
	payment_amount numeric(14, 2),
	shipping_plan_datetime timestamp,
	transfer_type_id bigint,
	shipping_country_id bigint,
	agreement_id bigint,
	
	foreign key (transfer_type_id) references shipping_transfer (id) on update cascade,
	foreign key (shipping_country_id) references shipping_country_rates (id) on update cascade,
	foreign key (agreement_id) references shipping_agreement (agreementid) on update cascade
);

drop table if exists shipping_status  cascade;
create table shipping_status(
	shippingid bigint primary key,
	status text ,
	state text ,
	shipping_start_fact_datetime timestamp,
	shipping_end_fact_datetime timestamp
);

create or replace view shipping_datamart as
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
	 inner join shipping_agreement sa on si.agreement_id = sa.agreementid ;