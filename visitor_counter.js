function increment_counter(){
	const request = new XMLHttpRequest()
	request.open("POST", "https://t90bhfhq2g.execute-api.us-east-1.amazonaws.com/increment_count_lambda")
	request.send()
};