#test/digital_object/digital_object_test.rb
require './test/test_helper'

class CordraRestClientDigitalObjectTest < Minitest::Test
	# basic test 
	def test_exists
		assert CordraRestClient::DigitalObject
	end
	  
	# 1 test retrieve object by ID
	def test_retrieve_object_by_id
		VCR.use_cassette('retrieve_object_id') do
			cdo = CordraRestClient::DigitalObject.find("20.5000.1025/B100003484")
			assert_equal CordraRestClient::DigitalObject, cdo.class
			  
			# Check that fields are accessible
			assert_equal "20.5000.1025/B100003484", cdo.id
			assert_equal "Digital Specimen", cdo.type
		end
	  end
	  # 2 test retrieve object creator, variant of  retrieve object by ID
	def test_retrieve_object_creator
		VCR.use_cassette('retrieve_object_attribute') do
			do_creator = CordraRestClient::DigitalObject.get_do_field("20.5000.1025/B100003484","creator")
			# Check object creator
		 	assert_equal "20.5000.1025/60c6d277a8bd81de7fdd", do_creator
		end
	 end
	  # pending testing of get payload, other attributes
	  
	  # 3 test create an object by type
	  def test_create_object_by_type
	    VCR.use_cassette('create_object') do
		  cred=JSON.parse(YAML::load_file('test/fixtures/credential.yml').to_json)
	      json = JSON.parse(File.read("test/fixtures/new_specimen.json"))

		  result=CordraRestClient::DigitalObject.create("RMNH.RENA.38646","Digital Specimen",json, cred["uc_1"])
	      
		  #check that the result is saved
		  assert_equal 200, result[:code]
		  assert_equal "OK", result["message"]
		end
	  end
	  
	  # 4 test create an object by type, FAIL
	  def test_create_object_by_type_fail
	    VCR.use_cassette('create_object_fail') do
		  cred=JSON.parse(YAML::load_file('test/fixtures/credential.yml').to_json)

	      json = JSON.parse(File.read("test/fixtures/new_specimen.json"))
		
		  result=CordraRestClient::DigitalObject.create("1a0beb212baaede1c10c","Digital Specimen",json, cred["uc_1"])
		  #check that the duplicate is rejected
		  assert_equal 409, result[:code]
		  assert_equal "Object already exists: 20.5000.1025/1a0beb212baaede1c10c", result["message"]
		end
	  end
	  
	  # 5 test update an object by ID
	  def test_update_object_by_id
	    VCR.use_cassette('edit_object') do
		  cred=JSON.parse(YAML::load_file('test/fixtures/credential.yml').to_json)
		  json = JSON.parse(File.read("test/fixtures/edit_specimen.json"))
		  id = json["id"] 
		  json["id"] = "" #id cannot be updated
		  result=CordraRestClient::DigitalObject.update(id, json, cred["uc_1"])

		  #check that the result is saved
		  assert_equal 200, result[:code]
		  assert_equal "OK", result["message"]
		end
	  end
	  
	  # 6 test delete an object by ID
	  def test_delete_object_by_id
	    VCR.use_cassette('delete_object') do
		  cred=JSON.parse(YAML::load_file('test/fixtures/credential.yml').to_json)
		  id = "20.5000.1025/newspecimen03" 
		  result=CordraRestClient::DigitalObject.delete(id, cred["uc_1"])

		  #check that the result is saved
		  assert_equal 200, result[:code]
		  assert_equal "OK", result["message"]
		end
	  end
	  
	  # 7 test search for objects
	  def test_search_for_objects
	    VCR.use_cassette('search_objects') do
	      list_cdo = CordraRestClient::DigitalObject.search("Digital Specimen")
	      assert_equal Hash, list_cdo.class
		  
	      # Check that fields are accessible
	      assert_equal 1, list_cdo["pageNum"]
		  assert_equal 10, list_cdo["pageSize"]
		  assert_equal 24, list_cdo["size"]
		  assert_equal Array, list_cdo["results"].class
	    end
	  end
	  # 8 test retrieves an object via the Handle System web proxy
	  def test_retrieve_objects_via_handle
	    VCR.use_cassette('get_object_hanlde') do
	      redirection = CordraRestClient::DigitalObject.handle_find("20.5000.1025/B100003484")
	      assert_equal String, redirection.class
		  
	      # Check that fields are accessible
		  assert_match /Handle Redirect/, redirection
		  assert_match /B100003484/, redirection
	    end
	end  
    
	# 9 test modify object ACL

	def test_object_acl_set
		VCR.use_cassette('object_acl_set') do
			cred=JSON.parse(YAML::load_file('test/fixtures/credential.yml').to_json)
			json = JSON.parse(File.read("test/fixtures/acl_list.json"))
			id = "20.5000.1025/RMNH.RENA.44084" 
			result=CordraRestClient::DigitalObject.set_premissions(id, json, cred["uc_1"])
			#check that the result is saved
			assert_equal 200, result[:code]
			assert_equal "OK", result["message"]
			assert_equal 4, result.length
			assert_equal 1, result["readers"].length
			assert_equal '20.5000.1025/1517d545cc11283e2360', result["readers"][0]
		end
	end
        # 10 test get object ACL
	def test_object_acl_get
		VCR.use_cassette('object_acl_get') do
			cred=JSON.parse(YAML::load_file('test/fixtures/credential.yml').to_json)
			json = JSON.parse(File.read("test/fixtures/acl_list.json"))
			id = "20.5000.1025/RMNH.RENA.38646" 
			result=CordraRestClient::DigitalObject.get_acl(id, json, cred["uc_1"])
			
			#check result returned
			assert_equal 2, result.length
			assert_equal 2, result["readers"].length
			assert_equal '20.5000.1025/1517d545cc11283e2360', result["readers"][0]
			assert_equal '20.5000.1025/1517d545cc11283e2360', result["writers"][0]
		end
	end
	
	# 11. test get object schema
	# 
	def test_modify_object_permissions
		VCR.use_cassette('get_schema') do
			schema_type="Digital%20Specimen"
			result=CordraRestClient::DigitalObject.get_schema(schema_type)
			do_schema = JSON.parse(result.body)
			#check that the result is saved
			assert_equal "object", do_schema["type"] 
			assert_equal "Digital Specimen", do_schema["title"]
		end
	end

end

