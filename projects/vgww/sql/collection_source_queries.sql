
drop function if exists dbo.fn_termTermAGG
go
drop function if exists dbo.fn_termURIAGG
go

drop type if exists termMapTable
go
create type termMapTable as table  (
	uri nvarchar(512),
	term nvarchar(512)
)
go

create function dbo.fn_termURIAGG(@mapTable termMapTable readonly, @termType nvarchar(512), @objectID integer)
returns nvarchar(max)
as
begin
	return
	( select STUFF(
			(	select
					';' + m.uri
				from tmsprivateextract.dbo.view_tms_objects_terms_all_types t 
				join @mapTable m on m.term = t.term
				where t.termtype=@termType and t.objectid=@objectID
				FOR XML PATH('')
			), 
			1, 1, ''
		)
	)
end
go

create function dbo.fn_termTermAGG(@mapTable termMapTable readonly, @termType nvarchar(512), @objectID integer)
returns nvarchar(max)
as
begin
	return
	( select STUFF(
			(	select
					';' + m.term
				from tmsprivateextract.dbo.view_tms_objects_terms_all_types t 
				left join @mapTable m on m.term = t.term
				where t.termtype=@termType and t.objectid=@objectID
				FOR XML PATH('')
			), 
			1, 1, ''
		)
	)
end
go

drop function if exists dbo.fn_objectDimensions
go

create function dbo.fn_objectDimensions(@element nvarchar(64), @units nvarchar(32), @objectID integer)
returns nvarchar(max) as
begin
	declare @res nvarchar(max)
	select @res = 
		concat(
			( select format(dimension,'N2')
			  from tmsprivateextract.dbo.view_objdimensions 
			  where objectID=@objectID and element=@element and unitName=@units and dimensionType='height'
			),' x ',
			( select format(dimension,'N2')
			  from tmsprivateextract.dbo.view_objdimensions 
			  where objectID=@objectID and element=@element and unitName=@units and dimensionType='width'
			), ' cm'
		)
	if @res = ' x  cm' 
		set @res=null
	return @res
end
go

drop function if exists dbo.fn_formatULANURI;
go

create function dbo.fn_formatULANURI(@ulanID nvarchar(64))
returns nvarchar(512) as 
begin
	return case
		when @ulanID is null then null
		else concat('http://vocab.getty.edu/ulan/',@ulanID)
	end
end
go


drop view if exists dbo.vw_VGWWObjects
go

create view dbo.vw_VGWWObjects as
select o.*, oo.CatRais from x_objects o
join x_objects_constituents oc on oc.objectID = o.objectID and oc.roleType='artist' and displayOrder=1 
join tmsprivateextract.dbo.view_objects oo on oo.ObjectID=o.objectID
where o.accessionNum in (
	'1943.3.8221',
	'1951.10.32',
	'1951.10.33',
	'1963.10.30',
	'1963.10.31',
	'1963.10.151',
	'1963.10.152',
	'1963.10.153',
	'1969.14.1',
	'1970.17.34',
	'1983.1.21',
	'1985.64.91',
	'1991.67.1',
	'1991.217.65',
	'1991.217.66',
	'1991.217.67',
	'1991.217.68',
	'1992.51.6',
	'1992.51.10',
	'1995.47.44',
	'1998.74.5',
	'2013.122.1',
	'2014.18.13'
)
and o.classification='Painting'
go

declare @map termMapTable
insert into @map (uri, term) values 
-- TGN Locations
('http://vocab.getty.edu/tgn/7006810',  'The Hague'),
('http://vocab.getty.edu/tgn/7006835',	'Nuenen'),
('http://vocab.getty.edu/tgn/7008038',	'Paris'),
('http://vocab.getty.edu/tgn/7008775',	'Arles'),
('http://vocab.getty.edu/tgn/7006810',	'''s-Gravenhage'),
('http://vocab.getty.edu/tgn/7008030',	'Auvers-sur-Oise'),
('http://vocab.getty.edu/tgn/7250304',	'Parijs'),
('http://vocab.getty.edu/tgn/7007856',	'Antwerpen'),
('http://vocab.getty.edu/tgn/7006824',	'Etten'),
('http://vocab.getty.edu/tgn/7003614',	'Drenthe'),
('http://vocab.getty.edu/tgn/7008792',	'Saintes-Maries-de-la-Mer'),
('http://vocab.getty.edu/tgn/7007868',	'Bruxelles'),
('http://vocab.getty.edu/tgn/7006952',	'Amsterdam'),
('http://vocab.getty.edu/tgn/1026382',	'Cuesmes'),
('http://vocab.getty.edu/tgn/1047973',	'Nieuw Amsterdam'),
('http://vocab.getty.edu/tgn/1047843',	'Helvoirt'),
('http://vocab.getty.edu/tgn/7006798',	'Dordrecht'),
('http://vocab.getty.edu/tgn/7012090',	'Isleworth'),
('http://vocab.getty.edu/tgn/7011562',	'Ramsgate'),
('http://vocab.getty.edu/tgn/7006842',	'Eindhoven'),
('http://vocab.getty.edu/tgn/7016995',	'Laken'),
('http://vocab.getty.edu/tgn/7007865',	'Borinage'),
('http://vocab.getty.edu/tgn/7009654',	'Saint-Rémy-de-Provence'),
('http://vocab.getty.edu/tgn/7008783',	'Montmajour'),

-- Visual Works by material or technique, aka "Classification"
('http://vocab.getty.edu/aat/300033618','Painting'),
('http://vocab.getty.edu/aat/300033973','Drawing'),
('http://vocab.getty.edu/aat/300041273','Print'),

-- Media / Materials
('http://vocab.getty.edu/aat/300015050','unanalyzed'),					
('http://vocab.getty.edu/aat/300015050','oil paint'),					
('http://vocab.getty.edu/aat/300022464','reed pen'),					
('http://vocab.getty.edu/aat/300011098','squared in graphite'),			
('http://vocab.getty.edu/aat/300011727','chalk'),						
('http://vocab.getty.edu/aat/300022414','charcoal'),					
('http://vocab.getty.edu/aat/300011098','graphite'),					
('http://vocab.getty.edu/aat/300404676','pen and ink'),					
('http://vocab.getty.edu/aat/300011727','verso chalked for transfer'),	

-- Support
('http://vocab.getty.edu/aat/300162391','fabric'),
('http://vocab.getty.edu/aat/300014078','canvas'),			
('http://vocab.getty.edu/aat/300014069','linen'),			
('http://vocab.getty.edu/aat/300014069','linen-type'),
('http://vocab.getty.edu/aat/300014109','paper'),					
('http://vocab.getty.edu/aat/300014224','paperboard-cardboard'),
('http://vocab.getty.edu/aat/300014184','laid'),	
('http://vocab.getty.edu/aat/300014187','wove'),				
('http://vocab.getty.edu/aat/300011914','wood'),

-- Technique
('http://vocab.getty.edu/aat/300053412','stumping'),
('http://vocab.getty.edu/aat/300054216','painted surface'),

-- Subject Types
('http://vocab.getty.edu/aat/300015638','still life'),
('http://vocab.getty.edu/aat/300189808','figures'),
('http://vocab.getty.edu/aat/300015636','landscape'),
('http://vocab.getty.edu/aat/300015571','cityscapes'),
('http://vocab.getty.edu/aat/300015637','portraits'),
('http://vocab.getty.edu/aat/300124534','self'),
('http://vocab.getty.edu/aat/300189568','nudes'),
('http://vocab.getty.edu/aat/300117546','seascapes'),
('http://vocab.getty.edu/aat/300139140','genre'),
('http://vocab.getty.edu/aat/300263554','animal paintings'),
('http://vocab.getty.edu/aat/300124520','interior views'),
('http://vocab.getty.edu/aat/300236227','townscapes'),

-- Reference Formats
('http://vocab.getty.edu/aat/300026657','Periodical'),
('http://vocab.getty.edu/aat/300026623','NGA Systematic Catalogue'),
('http://vocab.getty.edu/aat/300026656','Newspaper'),
('http://vocab.getty.edu/aat/300026096','Exhibition Catalogue'),
('http://vocab.getty.edu/aat/300026291','Essay'),
('http://vocab.getty.edu/aat/300129439','Encylopedia'),
('http://vocab.getty.edu/aat/300026186','Dictionary'),
('http://vocab.getty.edu/aat/300054792','Colloquium/Symposium'),
('http://vocab.getty.edu/aat/300417819','Collection Catalogue'),
('http://vocab.getty.edu/aat/300026061','Catalogue Raisonné'),
('http://vocab.getty.edu/aat/300060417','Monograph'),
('http://vocab.getty.edu/aat/300215390','Academic Journal'),
('http://vocab.getty.edu/aat/300312076','Ph.D. Dissertation'),
('http://vocab.getty.edu/aat/300026480','Review')

select 
	'National Gallery of Art' as [Current_owner],
	'http://vocab.getty.edu/ulan/500115983' as [Owner_URI],
	o.accessionNum as [Accession_no],
	o.creditLine as [Credit_line],
	c.forwardDisplayName as [Artist],
	dbo.fn_formatULANURI(c.ULANID) as [Artist_URI],
	o.title as [Title],
	null as [Title_FR],
	null as [Title_DE],
	null as [Other_(former)_title],
	null as [Other_(former)_title_FR],
	null as [Other_(former)_title_DE],
	o.displayDate as [Date_description],
	o.beginYear as [Start_date],
	o.endYear as [End_date],
	dbo.fn_termTermAGG(@map, 'Production Location', o.objectid) as [Location_made],
	dbo.fn_termURIAGG(@map, 'Production Location', o.objectid) as [Location_URI],
	o.classification as [Object_category],
	(	select uri 
		from @map 
		where term = o.classification
	) as [Object_category_URI],

	o.medium as [Material_statement],
	dbo.fn_termTermAGG(@map, 'Media', o.objectid) as [Material],
	dbo.fn_termURIAGG(@map, 'Media', o.objectid) as [Material_URI],
	dbo.fn_termTermAGG(@map, 'Support', o.objectid) as [Support],
	dbo.fn_termURIAGG(@map, 'Support', o.objectid) as [Support_URI],
	dbo.fn_termTermAGG(@map, 'Technique', o.objectid) as [Technique],
	dbo.fn_termURIAGG(@map, 'Technique', o.objectid) as [Technique_URI],

	dbo.fn_objectDimensions('overall','centimeters',o.objectid) as [Dimensions],

	
	o.CatRais as [De-la-Faille_cat-no],
	null as [Hulsker_cat-no],
	dbo.fn_termTermAGG(@map, 'Theme', o.objectid) as [Subject_type],
	dbo.fn_termURIAGG(@map, 'Theme', o.objectid) as [Subject_type_URI],
	null as [Signature],	
	o.inscription as [Inscription],	
	o.watermarks as [Watermark],	
	null as [Sticker],	
	o.provenanceText as [Provenance_descr],	
	null as [VGW-URI],
	concat('https://api.nga.gov/iiif/',i.uuid) as [Digital_image_URL],	
	null as [Digital_image_filename]
from vw_VGWWObjects o
join x_objects_constituents oc on oc.objectID = o.objectID and oc.roleType='artist' and displayOrder=1 
join x_constituents c on c.constituentID=oc.constituentID
left join x_published_images i on i.depictsTMSObjectID = o.objectID and i.viewType='primary' and i.sequence='0' and i.isPublic=1
order by o.accessionNum


select 
	o.accessionNum as [Object_ID],
	o.CatRais as [De-la-Faille_cat-no],
	null as [type-of-activity],
	null as [type-of-activity_URI],
	oc.beginYear as [activity-start-date],
	oc.endYear as [activity-end-date],
	c.forwardDisplayName as [transferred-to],
	dbo.fn_formatULANURI(c.ULANID) as [transferred-to_URI],
	null as [activity-note]
from vw_VGWWObjects o
join x_objects_constituents oc on oc.objectID=o.objectID and oc.roleType='owner'
join x_constituents c on c.constituentID = oc.constituentID
order by o.objectID, oc.displayOrder


/*
select 
	o.accessionNum,
	o.CatRais as [De-la-Faille_cat-no],
	ex.exhTitle as [name],
	c.forwardDisplayName as [organisation],
	dbo.fn_formatULANURI(c.ULANID) as organisation_URI,
	cast(v.venueOpenDate as date) as [start_date],
	cast(v.venueCloseDate as date) as [end_date],
	null as [place],
	null as [place_URI]

from vw_VGWWObjects o
join tmsprivateextract.dbo.x_objects_exhibitions oe on oe.objectID=o.objectID
join tmsprivateextract.dbo.x_exhibitions ex on ex.exhibitionID=oe.exhibitionID
join tmsprivateextract.dbo.x_exhibitions_venues v on v.exhibitionID=ex.exhibitionID and v.venueApproved = 1
join x_constituents c on c.constituentID=v.constituentID
order by ex.exhTitle, v.venueOpenDate
*/

select 
	o.accessionNum as [Object_ID],
	o.CatRais as [De-la-Faille_cat-no],
	f.Format as [type-of-literature],
	t.uri as [type-of-literature_URI],
	m.YearPublished as [year_begin],
	m.YearPublished as [year_end],
	m.Title as [title],
	null as [ISBN],
	m.copyright as [author(s)],
	null as [author_URI],
	null as [in-exhibition-catalog],
	null as [in-exhibition-catalog_ISBN],
	null as [in-journal],
	null as [in-journal_ISSN],
	m.Series as [in-series],
	null as [in-series_ISSN],
	m.Volume as [in-volume],
	m.PlacePublished as [publication-place],
	null as [publication-place_URI],
	null as [publisher],
	null as [publisher_URI],
	x.appendage as [pagination-statement]
	
from vw_VGWWObjects o
join TMSPrivateExtract.dbo.TMS_REFXREFS x on tableid=108 and x.id=o.objectID
join TMSPrivateExtract.dbo.TMS_REFERENCEMASTER m on m.ReferenceID=x.ReferenceID
join TMS2017.dbo.RefFormats f on f.FormatID=m.FormatID
left join @map t on t.term = f.Format collate database_default

-- technical-documentation
select 
	o.accessionNum as [Object_ID],
	o.CatRais as [De-la-Faille_cat-no],
	null as [type-of-research],
	null as [type-of-research_URI],
	null as [type-of-documentation],
	null as [type-of-documentation_URI],
	null as [start_date],
	null as [end_date],
	null as [title],
	null as [creator],
	null as [creator_URI],
	null as [Digital_image_URL],
	null as [Digital_image_filename]
from vw_VGWWObjects o
