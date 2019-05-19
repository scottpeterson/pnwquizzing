Vue.http.get( cntlr + "tool/register_data" ).then( function (response) {
    var data                = response.body;
    data.deleted_persons    = [];
    data.final_registration = 0;

    var vm = new Vue({
        el      : "#register",
        data    : data,
        methods : {
            reorder : function ( direction, person_index, team_index ) {
                if ( team_index > -1 ) {
                    var element = this.teams[team_index].splice( person_index, 1 )[0];

                    if ( direction == -1 ) {
                        if ( person_index != 0 ) {
                            this.teams[team_index].splice( person_index - 1, 0, element );
                        }
                        else {
                            var target = team_index - 1;
                            if ( target < 0 ) target = this.teams.length - 1;
                            this.teams[target].push(element);
                        }
                    }
                    else if ( direction == 1 ) {
                        if ( person_index != this.teams[team_index].length ) {
                            this.teams[team_index].splice( person_index + 1, 0, element );
                        }
                        else {
                            var target = team_index + 1;
                            if ( target > this.teams.length - 1 ) target = 0;
                            this.teams[target].unshift(element);
                        }
                    }

                    if ( this.teams[team_index].length == 0 ) this.teams.splice( team_index, 1 );
                }
                else {
                    var element = this.non_quizzers.splice( person_index, 1 )[0];

                    if ( direction == -1 ) {
                        if ( person_index != 0 ) {
                            this.non_quizzers.splice( person_index - 1, 0, element );
                        }
                        else {
                            this.non_quizzers.push(element);
                        }
                    }
                    else if ( direction == 1 ) {
                        if ( person_index != this.non_quizzers.length ) {
                            this.non_quizzers.splice( person_index + 1, 0, element );
                        }
                        else {
                            this.non_quizzers.unshift(element);
                        }
                    }
                }
            },

            delete_person : function ( person_index, team_index ) {
                if ( team_index > -1 ) {
                    var registration_id = this.teams[team_index][person_index].registration_id || 0;
                    if (registration_id) this.deleted_persons.push(registration_id);

                    this.teams[team_index].splice( person_index, 1 );
                    if ( this.teams[team_index].length == 0 ) this.teams.splice( team_index, 1 );
                }
                else {
                    var registration_id = this.non_quizzers[person_index].registration_id || 0;
                    if (registration_id) this.deleted_persons.push(registration_id);

                    this.non_quizzers.splice( person_index, 1 );
                }

                this.nav_content_align();
            },

            add_team : function () {
                var team = [];
                this.teams.push(team);
                this.add_quizzer(team);
            },

            add_quizzer : function (team) {
                var quizzer = { attend : true, house : true, lunch : true };
                team.push(quizzer);
                this.add_watch(quizzer);
                this.nav_content_align();
            },

            add_non_quizzer : function () {
                var non_quizzer = { attend : true, house : true, lunch : true };
                this.non_quizzers.push(non_quizzer);
                this.add_watch(non_quizzer);
                this.nav_content_align();
            },

            save_registration : function () {
                var register     = document.createElement("form");
                register.action  = cntlr + "tool/register";
                register.method  = "post";
                register.enctype = "multipart/form-data";

                var register_input   = document.createElement("input");
                register_input.name  = "data";
                register_input.value = JSON.stringify(data);

                register.appendChild(register_input);
                document.body.appendChild(register);

                register.submit();
            },

            add_watch : function (record) {
                this.$watch(
                    function () {
                        return record.attend;
                    },
                    ( function () {
                        var _record = record;

                        return function (attend) {
                            if ( attend == null ) return;
                            _record.house = attend;
                            _record.lunch = attend;
                        }
                    } )()
                );
            },

            nav_content_align : function () {
                this.$nextTick( function () {
                    nav_content_align.align();
                } );
            }
        },

        mounted : function () {
            for ( var t = 0; t < this.teams.length; t++ ) {
                for ( var q = 0; q < this.teams[t].length; q++ ) {
                    this.add_watch( this.teams[t][q] );
                }
            }

            for ( var n = 0; n < this.non_quizzers.length; n++ ) {
                this.add_watch( this.non_quizzers[n] );
            }

            this.nav_content_align();
        }
    });
});
