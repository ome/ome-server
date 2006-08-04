% returns the number of significant digits two numbers agree on
% e.g.:
% 	suppose vec_a is [123456] and matrix_b is [123457] then compute_sig_digits(vec_a, matrix_b)
%	would return 5 as vec_a and matrix_b share 5 significant digits (1,2,3,4,5).

function sig_digits = compute_sig_digits (matrix_a, matrix_b)
[rows, columns] = size(matrix_a);
sig_digits = zeros(rows, columns);

for i=1:rows
	for j=1:columns
		% If both signatures are nan, then they agree exactly. 
		% Perfect agreement is flagged as 16
		if( isnan( matrix_a(i,j) ) && isnan( matrix_b(i,j) ) )
			sig_digits(i,j) = 16;
		% If only one signatures is nan, then they disagree in an extreme way.
		% This is flagged as -1
		elseif( isnan( matrix_a(i,j) ) || isnan( matrix_b(i,j) ) )
			sig_digits(i,j) = -1;
		% If both are normal numbers, then calculate the number of significant
		% digits to which they agree.
		else
			diff_vec = abs(matrix_a(i,j) - matrix_b(i,j));
			avg_vec  = abs(matrix_a(i,j)) + abs(matrix_b(i,j));
			avg_vec  = avg_vec/2;
			
			if (abs(diff_vec) < eps)
				sig_digits(i,j) = 16;
			else 
				sig_digits(i,j) = ceil(log10(avg_vec))-ceil(log10(diff_vec));
			end
		end
	end
end