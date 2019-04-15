-- Convert a hexadecimal value to its corresponding TIMESTAMP, displaying the results using
-- the current NLS settings. This version can be used for both TIMESTAMP and TIMESTAMP WITH
-- LOCAL TIME ZONE datatypes, which are stored using the same internal representation,
-- although the results are always provided as a plain TIMESTAMP.
--
-- The value to be converted should be given as the only parameter, and must be either 14 or
-- 22 characters in length... representing a 7 or 11 byte value. The former indicates that no
-- fractional seconds are stored, matching the internal representation of the DATE datatype.
--
with data as (
   select '&1' raw_value from dual
)
select to_timestamp ( case
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
                      to_char( to_number( substr( raw_value, 13, 2 ), 'XX' ) - 1,          'FM00' ) || '.' ||
                      case
                         when length( raw_value ) = 14 then  '000000000'
                         else to_char( to_number( substr( raw_value, 15, 8 ), 'XXXXXXXX' ), 'FM000000000' )
                      end,
                      'FXAD YYYY-MM-DD HH24:MI:SS.FF9'
                    ) timestamp
   from data;
