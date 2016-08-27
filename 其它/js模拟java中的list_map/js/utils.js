/**************************************************************
*	ģ��Java�е�ArrayList
**************************************************************/

/**
 * Title:����
 * Description:
 * Created on 2007-12-27
 * @author ghostone
 * @Email:zitee@163.com
 * @version 1.0
 * Modify on 
 * Description:
 * Finished on 
 */
function List(){

	this.length=0;
	this.array = new Array();
	this.position = 0;

	//���һ��Ԫ��
	this.add = function(obj){
			this.array[this.length]=obj;
			this.length++;
		}
	//ɾ��һ��Ԫ��
	this.remove = function(position){
			if(position < this.length && position >= 0 && this.length>0){
				for(var i=position;i<this.length-1;i++){
					this.array[i]=this.array[i+1];
				}
				this.length--;
			}
		}
	//��ȡһ��Ԫ��
	this.get = function(position){
			if(position < this.length && position >= 0 && this.length>0){
				return this.array[position];
			}
	}
	//ɾ������Ԫ��
	this.removeAll = function(){
			this.length=0;
		}
	//��ȡԪ������
	this.toArray = function(){
			var arr = new Array();
			for(var i=0;i<this.length;i++){
				arr[i]=this.array[i];
			}
			return arr;
		}
	//��ȡԪ�ظ���
	this.size = function(){
			return this.length;
		}
}



/**************************************************************
*	ģ��Java�е�Map
**************************************************************/

/**
 * Title:Map�е�Ԫ��
 * Description:
 * Created on 2007-12-27
 * @author ghostone
 * @Email:zitee@163.com
 * @version 1.0
 * Modify on 
 * Description:
 * Finished on 
 */
function MapElement(){
	this.key="";
	this.value="";
}

/**
 * Title:Map
 * Description:
 * Created on 2007-12-27
 * @author ghostone
 * @Email:zitee@163.com
 * @version 1.0
 * Modify on 
 * Description:
 * Finished on 
 */
function Map(){

	this.list = new List();

	//����Ԫ��
	this.put = function(key,value){
			for(var i=0;i<this.list.size();i++){
				if(this.list.get(i).key==key){
					this.list.get(i).value=value;
					return;
				}
			}
			var element = new MapElement();
			element.key = key;
			element.value=value;
			this.list.add(element);
		}
	//��ȡԪ��
	this.get = function(key){
			for(var i=0;i<this.list.size();i++){
				if(this.list.get(i).key==key){
					return this.list.get(i).value;
				}
			}
			return null;
		}
	//��ȡԪ�ظ���
	this.size = function(){
			return this.list.size();
		}
	//��ȡ���е�KEY
	this.getKeys = function(){
			var arr = new Array();
			for(var i=0;i<this.list.size();i++){
				arr[i]=this.list.get(i).key;
			}
			return arr;
		}
}

/**************************************************************
*	ģ��Java�е�Set
**************************************************************/
function Set(){

	this.list = new List();
	
	//����Ԫ��
	this.add = function(obj){
		var size = this.list.size();
		//alert(size);
		for(var pos=0;pos<size;pos++){
			var value = this.list.get(pos);
			//alert(value);
			if(value == obj){
				//alert('value == obj:'+obj);
				return;
			}
		}
		this.list.add(obj);
		//alert(this.list.size());
	}
	
	//ɾ��Ԫ��
	this.remove = function(obj){
		var size = this.list.size();
		for(var pos=0;pos<size;pos++){
			var value = this.list.get(pos);
			if(value == obj){
				this.list.remove(pos);
				return;
			}
		}
	}

	//toString
	this.toString = function(){
		var values = '';
		var size = this.list.size();
		for(var pos=0;pos<size;pos++){
			var value = this.list.get(pos);
			if(pos == (size-1)){
				values = values + value;
			}else{
				values = values + value + ",";
			}
		}
		return values;
	}
}