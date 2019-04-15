-- Convert a hexadecimal value to its corresponding DATE, displaying the results using
-- the current NLS settings.
--
-- The value to be converted should be given as the only parameter, and must be 14 characters
-- in length... representing a 7 byte value.
--
with data as (
   select '&1' raw_value from dual
)
select to_date ( case
                    when to_number( substr( raw_value, 1, 2 ), 'XX' ) - 100 < 0 then 'BC '
                    when to_number( substr( raw_value, 3, 2 ), 'XX' ) - 100 < 0 then 'BC '
                    else 'AD '
                 end                                                                           ||
                 to_char( abs( to_number( substr( raw_value,  1, 2 ), 'XX' ) - 100 ), 'FM00' ) ||
                 to_char( abs( to_number( substr( raw_value,  3, 2 ), 'XX' ) - 100 ), 'FM00' ) || '-' ||
                 to_char( to_number( substr( raw_value,  5, 2 ), 'XX' ),              'FM00' ) || '-' ||
                 to_char( to_number( substr( raw_value,  7, 2 ), 'XX' ),              'FM00' ) || ' ' ||
                 to_char( to_number( substr( raw_value,  9, 2 ), 'XX' ) - 1,          'FM00' ) || ':' ||
                 to_char( to_number( substr( raw_value, 11, 2 ), 'XX' ) - 1,          'FM00' ) || ':' ||
                 to_char( to_number( substr( raw_value, 13, 2 ), 'XX' ) - 1,          'FM00' ),
                 'FXAD YYYY-MM-DD HH24:MI:SS'
               ) "DATE"
   from data;
