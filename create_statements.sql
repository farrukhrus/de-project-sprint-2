drop table if exists shipping_country_rates cascade;
drop table if exists shipping_agreement  cascade;
drop table if exists shipping_transfer  cascade;
drop table if exists shipping_info  cascade;
drop table if exists shipping_status  cascade;
drop table if exists shipping_datamart  cascade;

create table shipping_country_rates 
(
	id serial primary key,
	shipping_country text,
	shipping_country_base_rate numeric(14, 3)
);


create table shipping_agreement (
	agreementid bigint primary key,
	agreement_number text,
	agreement_rate numeric(14,2),
	agreement_commission numeric(14,2)
);


create table shipping_transfer (
	id serial primary key,
	transfer_type text,
	transfer_model text,
	shipping_transfer_rate numeric(14, 3)
);

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

create table shipping_status(
	shippingid bigint primary key,
	status text ,
	state text ,
	shipping_start_fact_datetime timestamp,
	shipping_end_fact_datetime timestamp
);

create table shipping_datamart (
	shippingid bigint,
	vendorid bigint,
	transfer_type text,
	full_day_at_shipping bigint,
	is_delay int,
	is_shipping_finish int,
	delay_day_at_shipping bigint,
	payment_amount numeric(14, 2),
	vat numeric(14, 2),
	profit numeric(14, 2)
);
