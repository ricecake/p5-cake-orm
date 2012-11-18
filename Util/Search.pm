add utility functions to provide a consistentninterfacenfor searching.  make search object, that takes params, and give s normalized parameters.  

function({
		from => {
				table => as,
				memo  => memo,
			},
		get  => {
				as => field,
				memo => id,
			},
		order => {
				by => {
					memo => subject,
					},
				collate => desc,
			},
		limit => 10,
		where => {
				memo => {
					field => [a,b,c,d],
					field2=> [a,b,c,d],
					field3 => {'!=' => [1,2,3,4]},
					field4 => {'or' => [{'!='=> [1,2,3,4]},{'=' => [5,6,7,8]}]}
				},
				as => {
					field => 4,
					id => \{ memo => id},
				},
			},
		});
essentially, for the where portion, you specify ors in arrays, and ands in hashes, as above.
if the value to a hash key is a hash, the first param is taken as the operator.
if the value is a hashrefref, it's taken as a reference to another field.'
so once you're in the where section, adding more hashes to a fields criteria is just more nesting of operators.
