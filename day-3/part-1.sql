/*
-- Set up input (engine schematic)
drop foreign table if exists aoc2023_d3_input;
create
	foreign table aoc2023_d3_input (entry varchar)
	server aoc2023
	option (filename 'aoc-2023-day-3-input.txt')
;
*/

-- Day 3 Part 1

with recursive
searchable_entry as
(
	select
		row_number() over() line_number,
		entry,
		'[^.]|\d+' search_expression
	from
		aoc2023_d3_input
),
search_entry_result AS 
(
	select
		line_number,
		-1 character_index,
		0 end_match_string_index,
		null "match"
	from
		searchable_entry
	union
	select
		line_number,
		case
			when match_result.is_match = 1 then end_match_string_index
			else -1
		end character_index,
		match_result.end_match_string_index,
		case
			when match_result.is_match = 0 then null 
			else match_result."match"
		end match_result
	from
		(
			select coalesce(array_length(regexp_match(substring(entry, end_match_string_index
					+ coalesce(length("match"), 1), 1), search_expression), 1), 0) is_match,
					(regexp_match(substring(entry, end_match_string_index
					+ coalesce(length("match"), 1), length(entry)), search_expression))[1] "match",
					end_match_string_index + coalesce(length("match"), 1) end_match_string_index,
					se.*
			from search_entry_result ser
			join searchable_entry se
			on se.line_number = ser.line_number
		) match_result
	where
		length(entry) >= match_result.end_match_string_index
),
map_item as
(
	select
		row_number() over() identifier,
		match,
		line_number y,
		character_index begin_x,  -- inclusive
		character_index + length(match) - 1 end_x  -- inclusive
	from
		search_entry_result 
	where
		character_index >= 0
),
symbol as
(
	select
		*,
		begin_x x
	from
		map_item
	where
		match !~ '\d+'
),
part as
(
	select
		distinct
			mi.identifier map_item_identifier,
			mi.match::int part_number
	from
		symbol
	cross join (
		select
			*
		from
		(
			select 0 x
			union
			select 1
			union
			select -1
		) x,
		(
			select 0 y
			union
			select 1
			union
			select -1
		) y
		where
			not (x = 0 and y = 0)
	) adjacency_offset
	cross join map_item mi
	where
		mi.match ~ '\d+'
		and symbol.y + adjacency_offset.y = mi.y
		and (symbol.x + adjacency_offset.x >= mi.begin_x
			and symbol.x + adjacency_offset.x <= mi.end_x)
)
select
	sum(part_number)
from
	part 
;