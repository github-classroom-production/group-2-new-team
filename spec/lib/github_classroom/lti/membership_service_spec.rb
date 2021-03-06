# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LTI::MembershipService do
  subject { described_class }
  let(:consumer_key)  { "valid_consumer_key" }
  let(:shared_secret) { "valid_shared_secret" }

  describe "membership service (LTI 1.1)", :vcr do
    # Official LTI reference tool consumer specifically for testing purposes. Response will be stored in VCR.
    let(:endpoint) { "http://ltiapps.net/test/tc-memberships.php/context/bcde6a55f4cad71bb7865a04a57823ec" }

    context "valid authentication" do
      let(:instance) { subject.new(endpoint, consumer_key, shared_secret) }

      it "gets all membership" do
        membership = instance.membership
        expect(membership).to_not be_empty

        expected_klass = GitHubClassroom::LTI::Models::CourseMember
        member = membership.first
        expect(member).to be_an_instance_of(expected_klass)
      end

      it "gets only instructors" do
        instructors = instance.instructors
        expect(instructors).to_not be_empty

        instructors.each do |i|
          expect(i.role).to include(a_string_matching(/Instructor/))
        end
      end

      it "gets only students" do
        students = instance.students
        expect(students).to_not be_empty

        students.each do |i|
          expect(i.role).to include(a_string_matching(/Student/)).or include(a_string_matching(/Learner/))
        end
      end
    end

    context "invalid authentication" do
      let(:instance) { subject.new(endpoint, "invalid" + consumer_key, "invalid" + shared_secret) }

      it "cannot get members" do
        expect { instance.membership }.to raise_error(Faraday::ClientError)
      end
    end
  end

  describe "membership extension (LTI 1.0)", :vcr do
    # rubocop:disable Metrics/LineLength
    let(:endpoint) { "https://trysakai.longsight.com/imsblis/service/" }
    let(:body_params) { { "id": "4d0a6e23e6902927ff0ad4e7869f7f5cb3c5b962cd7fbb796d87a4ceab90fadd:::ce59ead6-026b-4ba5-9464-568e131c0a77:::content:2586" } }
    # rubocop:enable Metrics/LineLength

    context "valid authentication" do
      let(:instance) { subject.new(endpoint, consumer_key, shared_secret, lti_version: 1.0) }

      it "gets membership" do
        membership = instance.membership(body_params: body_params)
        expect(membership).to_not be_empty

        expected_klass = GitHubClassroom::LTI::Models::CourseMember
        member = membership.first
        expect(member).to be_an_instance_of(expected_klass)
      end
    end
  end
end
