function increment_counter(){
	const xhr = new XMLHttpRequest()
	xhr.open("GET", "https://t90bhfhq2g.execute-api.us-east-1.amazonaws.com/test_deployment/increment_count_lambda", true)
	xhr.responseType = 'text';
	xhr.onload = () => {
  		if (xhr.readyState === xhr.DONE) {
			if (xhr.status === 200) {
					document.getElementById("counter").innerHTML = "You are visitor number: " + xhr.responseText
			}
  		}
	}
	xhr.send(null);
}
