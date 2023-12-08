/*
create extension file_fdw;

create server aoc2023 foreign data wrapper file_fdw;

drop foreign table if exists aoc2023_d8_input;
create
    foreign table aoc2023_d8_input (entry varchar)
    server aoc2023
    options (filename 'aoc-2023-day-8-input.txt')
;
*/

-- Day 8 Part 2

with recursive
instruction as
(
    select
        direction,
        index
    from
    (
        select
            entry directions
        from
            aoc2023_d8_input
        limit 1
    ) directions_line,
    unnest(regexp_split_to_array(directions, ''))
    with ordinality directions(direction, index)
),
map as
(
    select
        substring(entry, '(.*) =') node,
        substring(entry, '\((.*),') left,
        substring(entry, ', (.*)\)') right
    from
        aoc2023_d8_input
    offset 2
),
traversal as
(
    select
        node start_node,
        direction,
        map.left,
        map.right,
        1 step
    from
        map,
        instruction
    where
        index = 1
        and node like '__A'
    union
    select
        t.start_node,
        instruction.direction,
        map.left,
        map.right,
        step + 1
    from
        traversal t
    join
        map
    on
        case when t.direction = 'L' then t.left else t.right end = map.node
    join
        instruction
    on
        instruction.index = (step % (select count(*) from instruction)) + 1
    where
        map.node not like '__Z'
),
cycle as
(
    select
        *,
        row_number() over () row_number
    from
    (
        select
            start_node,
            max(step) length
        from
            traversal
        group by
            start_node
    ) cycle_length
),
lcm as
(
    select
        start_node,
        length,
        length::bigint current_lcm,
        row_number current_index
    from
        cycle
    union
    select
        c.start_node,
        c.length,
        lcm(current_lcm, c.length),
        current_index + 1
    from
        lcm
    join
        cycle c
    on
        c.row_number = current_index + 1
)
select
    max(current_lcm)
from
    lcm
;
