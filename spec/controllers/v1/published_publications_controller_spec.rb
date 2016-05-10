require 'rails_helper'

RSpec.describe V1::PublishedPublicationsController, type: :controller do

  describe "index" do
    before :each do
      @publication = create(:publication)
      @publication2 = create(:publication)
      publication_version = @publication.current_version

      @person = create(:xkonto_person)
      people2publication = create(:people2publication, publication_version: publication_version, person: @person)
      department = create(:department)
      create(:departments2people2publication, people2publication: people2publication, department: department)
    end

    context "for no given actor or registrator" do
      it "should return publications where current user is actor" do

        get :index, api_key: @xtest_key

        expect(response.status).to eq 200
        expect(json['publications'].count).to eq 1
        expect(json['publications'].first['id']).to eq @publication.id
      end
    end

    context "for actor logged_in_user when user has no Person object" do
      it "should return an error message" do

        get :index, api_key: @api_key

        expect(response.status).to eq 404
        expect(json['error']).to_not be nil
      end
    end

    context "for actor logged_in_user" do
      it "should return publications where current user is actor" do

        get :index, actor: 'logged_in_user', api_key: @xtest_key

        expect(response.status).to eq 200
        expect(json['publications'].count).to eq 1
        expect(json['publications'].first['id']).to eq @publication.id
      end
    end

    context "for registrator logged_in_user" do
      it "should return publications where current user has created or updated publication" do

        publication_version_2 = @publication2.current_version
        publication_version_2.update_attributes(updated_by: 'xtest')

        get :index, registrator: 'logged_in_user', api_key: @xtest_key

        expect(response.status).to eq 200
        expect(json['publications'].count).to eq 1
        expect(json['publications'].first['id']).to eq @publication2.id
      end
    end
    
    context "when there are publications different actor objects with the same xaccount" do
      it "should include publications for all actors of the current xaccount in the list" do
        publication3 = create(:publication)
        publication4 = create(:publication)
        publication_version3 = publication3.current_version
        publication_version4 = publication3.current_version

        person3 = create(:person)
        create(:xkonto_identifier, person: person3, value: 'xtest')
        
        people2publication = create(:people2publication, publication_version: publication_version3, person: person3)
        department = create(:department)
        create(:departments2people2publication, people2publication: people2publication, department: department)
        
        
        person4 = create(:person)
        create(:xkonto_identifier, person: person4, value: 'xother')
        people2publication = create(:people2publication, publication_version: publication_version4, person: person4)
        department = create(:department)
        create(:departments2people2publication, people2publication: people2publication, department: department)
        
        get :index, api_key: @xtest_key
        expect(json['publications'].count).to eq(2)
        pubids = json['publications'].map { |x| x['id']}
        expect(pubids).to include(publication3.id)
        expect(pubids).to_not include(publication4.id)
      end
    end
  end

  describe "create" do

    context "for an existing no deleted and draft publication" do
      context "with valid parameters" do
        it "should return updated publication" do
          create(:draft_publication, id: 45687)

          post :create, publication: {draft_id: 45687, title: "New test title"}, api_key: @api_key

          expect(json["publication"]).to_not be nil
          expect(json["publication"]).to be_an(Hash)
          expect(json["publication"]["title"]).to eq "New test title"
          expect(json["publication"]["published_at"]).to_not be nil
        end
      end
      context "with invalid parameters" do
        it "should return an error message" do
          create(:draft_publication, id: 45687)

          post :create, publication: {draft_id: 45687, publication_type: 'non_existing', title: "New test title"}, api_key: @api_key

          expect(json["publication"]).to be nil
          expect(json["error"]).to_not be nil
        end
      end
    end
    context "for a non existing draft id" do
      it "should return an error message" do
        post :create, publication: {draft_id: 999999}, api_key: @api_key

        expect(response.status).to eq 404
        expect(json["publication"]).to be nil
        expect(json["error"]).to_not be nil
      end
    end
    context "for a publication that is not a draft" do
      it "should return an error message" do
        create(:publication, id: 12234)

        post :create, publication: {draft_id: 12234}, api_key: @api_key

        expect(response.status).to eq 404
        expect(json["publication"]).to be nil
        expect(json["error"]).to_not be nil
      end
    end
    context "without giving a draft_id" do
      it "should return an error message" do
        post :create, publication: {}, api_key: @api_key

        expect(response.status).to eq 404
        expect(json["publication"]).to be nil
        expect(json["error"]).to_not be nil
      end
    end
  end

  describe "update" do

    context "for a non existing publication id" do
      it "should return an error message" do
        put :update, id: 9999, api_key: @api_key

        expect(response.status).to eq 404
        expect(json['publication']).to be nil
        expect(json['error']).to_not be nil
      end
    end
    context "for a draft publication" do
      it "should return an error message" do
        create(:draft_publication, id: 1234)

        put :update, id: 1234, api_key: @api_key

        expect(response.status).to eq 404
        expect(json['publication']).to be nil
        expect(json['error']).to_not be nil
      end
    end
    context "with person inc department" do
      it "should return a publication" do
        publication = create(:publication)
        person = create(:person)
        department = create(:department)

        put :update, id: publication.id, publication: {authors: [{id: person.id, departments: [department.as_json]}]}, api_key: @api_key
        publication_new = Publication.find_by_id(publication.id)

        expect(json['error']).to be nil
        expect(json['publication']['authors'][0]['id']).to eq person.id
        expect(json['publication']['authors'][0]['departments'][0]['id']).to eq department.id
        expect(publication_new.current_version.people2publications.size).to eq 1
        expect(publication_new.current_version.people2publications.first.departments2people2publications.count).to eq 1
      end

      it "should return a publication with an author list with presentation string on the form 'first_name last_name, year_of_birth (affiliation 1, affiliation 2)'" do
        person = create(:person, first_name: "Test", last_name: "Person", year_of_birth: 1980, affiliated: true)
        publication = create(:publication, id: 45687)

        department1 = create(:department, name_sv: "department 1")
        department2 = create(:department, name_sv: "department 2")
        department3 = create(:department, name_sv: "department 3")

        people2publication = create(:people2publication, publication_version: publication.current_version, person: person)

        create(:departments2people2publication, people2publication: people2publication, department: department1)
        create(:departments2people2publication, people2publication: people2publication, department: department2)
        create(:departments2people2publication, people2publication: people2publication, department: department3)

        put :update, id: 45687, publication: {title: "New test title", authors: [{id: person.id, departments: [department1.as_json, department2.as_json, department3.as_json]}]}, api_key: @api_key 

        expect(json["publication"]["authors"]).to_not be nil
        expect(json["publication"]["authors"][0]["presentation_string"]).to eq "Test Person, 1980 (department 1, department 2)"
      end
    end

    context "for an existing no deleted and published publication" do
      context "with valid parameters" do
        it "should return updated publication" do
          create(:publication, id: 45687)

          put :update, id: 45687, publication: {title: "New test title"}, api_key: @api_key 

          expect(json["error"]).to be nil
          expect(json["publication"]).to_not be nil
        end
      end
    end

    context "for an existing no deleted, published and bibl reviewed publication" do
      context "with valid parameters" do
        it "should return updated publication with empty bibl reviewed attributes" do
          create(:publication, id: 45687)

          put :update, id: 45687, publication: {title: "New test title"}, api_key: @api_key 

          expect(json["error"]).to be nil
          expect(json["publication"]).to_not be nil
          expect(json["publication"]["biblreviewed_at"]).to be nil
          expect(json["publication"]["biblreviewed_by"]).to be nil
        end
      end
    end

    context "for an existing no deleted, published and bibl unreviewed publication with a delay date set" do
      context "with valid parameters" do
        it "should return updated publication with reset delay parameters" do
          pub = create(:unreviewed_publication, id: 45687)
          delayed_time = DateTime.now + 2

          pub.update_attributes(biblreview_postponed_until: delayed_time, biblreview_postpone_comment: "Delayed")

          put :update, id: 45687, publication: {title: "New test title"}, api_key: @api_key 
          expect(json["error"]).to be nil
          expect(json["publication"]).to_not be nil
          expect(json["publication"]["biblreview_postponed_until"]).to_not eq delayed_time
          expect(json["publication"]["biblreview_postponed_comment"]).to be nil
        end
      end
    end
  end

end
