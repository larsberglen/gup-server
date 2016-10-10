require 'rails_helper'
require 'fileutils'

RSpec.describe V1::AssetDataController, type: :controller do

  before :each do
    @upload_root_dir = "#{Rails.root}/#{APP_CONFIG['file_upload_root_dir']}"
    FileUtils.mkdir_p(@upload_root_dir)

    create(:publication, id: 1)
    @publication = Publication.find(1)

    @pdf_file = fixture_file_upload('files/Testfile.pdf', 'application/pdf')
    @doc_file = fixture_file_upload('files/Testfile.doc', 'application/msword')
    @docx_file = fixture_file_upload('files/Testfile.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')
    @xls_file = fixture_file_upload('files/Testfile.xls', 'application/vnd.ms-excel')
    @xlsx_file = fixture_file_upload('files/Testfile.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    @jpg_file = fixture_file_upload('files/Testfile.jpg', 'image/jpeg')
    @txt_file = fixture_file_upload('files/Testfile.txt', 'text/plain')

  end
  
  after :each do
    FileUtils.rm_rf(@upload_root_dir)
  end


  describe "create" do
    it "should accept pdf file" do
      post :create, publication_id: @publication.id, file: @pdf_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
    end

    it "should accept doc file" do
      post :create, publication_id: @publication.id, file: @doc_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
    end
    
    it "should accept docx file" do
      post :create, publication_id: @publication.id, file: @docx_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
    end
    
    it "should accept xls file" do
      post :create, publication_id: @publication.id, file: @xls_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
    end
    
    it "should accept xlsx file" do
      post :create, publication_id: @publication.id, file: @xlsx_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
    end
    
    it "should accept jpg file" do
      post :create, publication_id: @publication.id, file: @jpg_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
    end
    
    it "should not accept txt file" do
      post :create, publication_id: @publication.id, file: @txt_file, api_key: @api_key
      expect(response.status).to eq(ErrorCodes::DATA_ACCESS_ERROR[:http_status])
      expect(json['error']).to_not be_nil
    end
    

    it "should require an existing publication" do
      post :create, publication_id: 999999, file: @txt_file, api_key: @api_key
      expect(response.status).to eq(ErrorCodes::OBJECT_ERROR[:http_status])
      expect(json['error']).to_not be_nil
    end

    it "should return an valid tmp token" do
      post :create, publication_id: @publication.id, file: @pdf_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
      expect(json['asset_data']['tmp_token'].eql?(Publication.find_by_id(1).asset_data.first.tmp_token)).to be_truthy
    end

    it "should save file in file system with a path based on checksum" do
      post :create, publication_id: @publication.id, file: @pdf_file, api_key: @api_key
      expect(response.status).to eq(200)
      expect(json['asset_data']).to_not be_nil
      assets = Publication.find_by_id(1).asset_data
      checksum = Publication.find_by_id(1).asset_data.first.checksum
      path = "#{@upload_root_dir}/#{checksum[0..1]}/#{checksum[2..3]}"
      expect(File.exist?("#{path}/#{checksum}.pdf")).to be_truthy
    end
  end

  describe "destroy" do
    it "should not delete a not-accepted asset" do
      post :create, publication_id: @publication.id, file: @pdf_file, api_key: @api_key
      expect(json['asset_data']['accepted']).to be_nil
      asset_id = Publication.find_by_id(1).asset_data.first.id
      delete :destroy, id: asset_id, api_key: @api_key
      expect(response.status).to_not eq(200)
      expect(json['error']).to_not be_nil
  
    end
  end
end