% Usage:
%	Just run personalizflights
% 
% You're welcome to add flights to "flights" data set, travelers to "travelers" data set
% and explore how the model works by changing factor-* parameters in Personalize().
% Also, add to "airlines" if you add new flights and/or airline policy to traveler data.
% Also, add to "classes" if you add new classes and/or class policy to traveler data.
%
% Works with Octave 3.4.3.  Not tested with Matlab, but should run with no or minor modifications.
%
classes = {'economy','first'};
seats = {'aisle','window','other','any'};
airlines = {'United','American','Delta','Alaska','SouthWest','jetBlue'};

travelers = {};
% name, airline preference, seat preference, ailine policy, class policy
travelers(1,:) = {'Carol Easton','SouthWest','aisle',{'SouthWest','United','Delta'},{'economy'}};
travelers(2,:) = {'Mary Mason','American','any',{'United','Alaska'},{'economy'}};
travelers(3,:) = {'Robert Meyer','United','window',{'Delta'},{'economy','first'}};
travelers(4,:) = {'John Doe','Delta','aisle',{'Delta'},{'economy'}};
travelers(5,:) = {'Tim McDonald','United','aisle',{'United','American'},{'economy','first'}};

for i=1:size(travelers,1)
assert(ismember(travelers{i,2},airlines));
assert(ismember(travelers{i,3},seats));
for k=1:size(travelers(i,:){4},2),
	assert(ismember(travelers(i,:){4}{k},airlines)); end
for k=1:size(travelers(i,:){5},2),
	assert(ismember(travelers(i,:){5}{k},classes)); end
end

flights = {};
% airline,flight number,stop overs,airfare,class,seat
flights(1,:) = {'United',143,1,220.45,'first','aisle'};
flights(2,:) = {'American',283,2,110.45,'economy','other'};
flights(3,:) = {'Delta',980,1,120.55,'economy','window'};
flights(4,:) = {'Alaska',123,0,100.70,'economy','aisle'};
flights(5,:) = {'United',348,0,220.45,'first','window'};
flights(6,:) = {'SouthWest',121,0,100.40,'economy','aisle'};
flights(7,:) = {'Delta',321,0,240.50,'first','aisle'};
flights(8,:) = {'United',301,0,120.45,'economy','other'};
flights(9,:) = {'American',799,1,230.20,'first','window'};
flights(10,:) = {'Alaska',549,0,110.60,'economy','aisle'};
flights(11,:) = {'jetBlue',149,0,105.60,'economy','other'};
flights(12,:) = {'jetBlue',327,0,213.60,'first','window'};
flights(13,:) = {'American',219,0,133.56,'economy','aisle'};
flights(14,:) = {'SouthWest',291,0,202.80,'first','window'};
flights(15,:) = {'SouthWest',355,0,128.30,'economy','other'};

for i=1:size(flights,1),
assert(ismember(flights{i,1},airlines));
assert(flights{i,3}<3); % stop overs
assert(ismember(flights{i,5},classes));
assert(ismember(flights{i,6},seats));
end

flights_personalized = zeros(size(flights));
flights_cost = zeros(size(flights_personalized,1),1);

assert(size(flights)==size(flights_personalized));

function FP = Personalize(flights, traveler)

	factor_stopover = 3.0;
	factor_airfare = 2.0;
	factor_airline_in_preference_in_policy = 0.0;
	factor_airline_out_preference_in_policy = 1.0;
	factor_airline_in_preference_out_policy = 4.0;
	factor_airline_out_preference_out_policy = 6.0;
	factor_class_in_policy = 0.0;
	factor_class_out_policy = 10.0;
	factor_seat_in_preference = 9.0;
	factor_seat_out_preference = 10.0;

	FP = zeros(size(flights));
	airfare_minimum = 100000000.0;
	airfare_average = 0.0;
	for i=1:size(flights,1),
		airfare = flights(i,:){4};
		if airfare<airfare_minimum, airfare_minimum = airfare; end
		airfare_average += airfare;
	end
	airfare_average/=size(flights,1);
	for i=1:size(flights,1),
		flight = flights(i,:);
		airline = flight{1};
		airline_preference = traveler{2};
		airline_policy = traveler{4};
		if ismember(airline,airline_policy),
			if ismember(airline,airline_preference), FP(i,1) = factor_airline_in_preference_in_policy;
			else FP(i,1) = factor_airline_out_preference_in_policy; end
		else
			if ismember(airline,airline_preference), FP(i,1) = factor_airline_in_preference_out_policy;
			else FP(i,1) = factor_airline_out_preference_out_policy; end
		end
		stop_over = flight{3} * factor_stopover;
		FP(i,3) = stop_over; 
		normalized_airfare = factor_airfare*(flight{4} - airfare_minimum)/(airfare_average - airfare_minimum);
		FP(i,4) = normalized_airfare;
		class = flight{5};
		class_policy = traveler{5};
		if ismember(class,class_policy), FP(i,5) = factor_class_in_policy;
		else FP(i,5) = factor_class_out_policy; end
		seat = flight{6};
		seat_preference = traveler{3};
		if strcmp(seat_preference,'any')==1 || ismember(seat,seat_preference), FP(i,6) = factor_seat_in_preference;
		else FP(i,6) = factor_seat_out_preference; end
	end
end

function PrintFlight(flight)
	no_of_stops = flight{3};
	if no_of_stops==0, strstops = 'non-stop';
	else strstops = strcat(num2str(no_of_stops),' stop'); end
	if no_of_stops>1, strstops = strcat(strstops,'s'); end
	str = strcat(flight{1},'#',num2str(flight{2}),' $',num2str(flight{4}),'(',flight{5},'/',flight{6},'/',strstops,')');
	fprintf(strcat(str,'\n'));
end

%
% main line code
%
fprintf(strcat('\n___ Original flight list\n'));
for k=1:size(flights,1)
	PrintFlight(flights(k,:));
end

fprintf(strcat('\n___ Airfare benchmark:\n'));
for k=1:size(classes,2),
	airfare_average = 0.0;
	count = 0;
	for i=1:size(flights,1),
		airfare = flights(i,:){4};
		class = flights(i,:){5};
		if strcmp(class,classes{k})==1, airfare_average += airfare; count+=1; end
	end
	if count>0,
		airfare_average/=count;
		str = strcat(classes{k},': $',num2str(airfare_average),'\n');
		fprintf(str);
	end
end

for i=1:size(travelers,1)
	flights_personalized = Personalize(flights,travelers(i,:));
	flights_cost = sum(flights_personalized,2);
	[flights_cost_sorted, idx] = sort(flights_cost, 'ascend');
	fprintf(strcat('\n___ Recommended flights for:', travelers(i,:){1}, '\n'));
	fprintf(strcat('___ Airline preference:', travelers(i,:){2}, '\n'));
	str_airline_policy = '';
	for k=1:size(travelers(i,:){4},2), str_airline_policy = strcat(str_airline_policy,',',travelers(i,:){4}{k}); end
	fprintf(strcat('___ Airline policy:', str_airline_policy, '\n'));
	fprintf(strcat('___ Seat preference:', travelers(i,:){3}, '\n'));
	str_class_policy = '';
	for k=1:size(travelers(i,:){5},2), str_class_policy = strcat(str_class_policy,',',travelers(i,:){5}{k}); end
	fprintf(strcat('___ Class policy:', str_class_policy, '\n'));
	for k=1:7 % size(flights_cost_sorted,1)
		PrintFlight(flights(idx(k),:));
	end
end

